# SiFive WorldGuard Technical Paper
SiFive Shield Open Secure Platform Architecture

**Version**: 2.4

> Converted from PDF using `pdftotext` (Poppler). Layout/tables may be imperfect.

## Contents
- 1 Introduction (p. 3)
  - 1.1 Glossary (p. 3)
- 2 Architectural Overview (p. 5)
  - 2.1 Features (p. 6)
  - 2.2 Fundamental Concepts (p. 7)
- 3 Security Rationale and Threat Model (p. 10)
- 4 Usage Models (p. 12)
  - 4.1 Multi-core SoC with Trusted Core (p. 12)
  - 4.2 Multi-core with M-mode Firmware as Trusted Agent (p. 13)
  - 4.3 Single Core (p. 16)
  - 4.4 Debug (p. 19)
  - 4.5 Bypass (p. 21)
- 5 Architecture and Implementation Details (p. 22)
  - 5.1 WID Representation (p. 22)
  - 5.2 Hardware Blocks (p. 22)
    - 5.2.1 Input Values (p. 23)
    - 5.2.2 wgMarkers (p. 23)
      - 5.2.2.1 wgMarkers for Non-wg-aware Agents (p. 24)
      - 5.2.2.2 wgMarkers for wg-aware Agents (p. 24)
      - 5.2.2.3 WID CSRs (p. 25)
      - 5.2.2.4 WID Delegation Example (p. 26)
      - 5.2.2.5 wgMarker Value Computation (p. 27)
    - 5.2.3 wgCheckers (p. 30)
      - 5.2.3.1 Interrupts and Error Registers (p. 31)
    - 5.2.4 Enabling and Locking Policies (p. 32)
  - 5.3 Software Configuration and Usage (p. 32)
    - 5.3.1 Default Configuration (p. 32)
    - 5.3.2 Secure Boot Process and Initial WorldGuard Configuration (p. 32)
- 6 Error Management (p. 34)
  - 6.1 Incorrect CSR Usage (p. 34)
  - 6.2 Speculative Accesses (p. 34)
- 7 WorldGuard Impact on Other Hardware Blocks (p. 35)
  - 7.1 Caches (p. 35)
  - 7.2 Tightly-Integrated Memory (TIM) (p. 36)
  - 7.3 Bus Fabric (p. 36)
  - 7.4 CLIC/PLIC (p. 36)
  - 7.5 Debug and Trace (p. 36)
    - 7.5.1 Debug Security Level (p. 37)
  - 7.6 System Bus Access (SBA) (p. 37)
- 8 References (p. 38)
## 1 Introduction

SiFive® Shield is an open, secure platform architecture that includes cryptographic engines, secure debug, and a hardware-enforced, multi-domain solution named SiFive WorldGuard. WorldGuard is a hardware-based software isolation solution for RISC-V cores. This paper discusses not only the WorldGuard architecture, but also enough about SiFive implementations of that architecture to make the concepts more concrete.

Software isolation is an important feature mandated by distinct concerns. The trend of increasing code size and complexity, different code origins, and the ways code is combined can introduce risks such that one set of software can impact another, intentionally or not. Bugs that cause unintentional malfunctions may drive safety concerns. A health or safety oriented device such as a medical device, automotive brake, or sensor must maintain its mission even if another piece of software running on the device exhibits erratic behavior. A credential oriented device such as a payment terminal, badge control system, or DRM equipped device must resist such misdirection and not compromise the assets it protects. If there is a weakness that allows a nefarious act to affect the software, then there is a concern about security. Robust solutions should ensure that failure of one piece of software does not impact the correct and full functioning of other software running on the same platform.

For the rest of this document, "wg" may be used to denote WorldGuard.

### 1.1 Glossary

```text
         Term                                           Meaning
 AMO                     Atomic Memory Operation

 AXI                     Advanced eXtensible Interface bus protocol

 BEU                     Bus Error Unit

 CMO                     Cache Maintenance Operation
```

```text
             Term                                      Meaning
 CSR                   Control and Status Register

 FSBL                  First Stage Boot Loader

 Initiator             The inclusive word for "master" block

 MMU                   Memory Management Unit

 PMC                   Power Management Controller

 Privilege modes       The RISC-V Instruction Set Manual, Volume II: Privileged Architec-
                       ture defines up to five privilege modes: M, [H]S, U, VS, VU
 REE                   Rich Execution Environment

 SBI                   Supervisor Binary Interface

 SKU                   Stock Keeping Unit

 Target                The inclusive word for "slave" block

 TEE                   Trusted Execution Environment

 TL                    TileLink bus protocol

 WID                   WorldGuard World Identifier

 WG                    WorldGuard

 XLEN                  Refers to the width of an integer register in bits (either 32 or 64)
```

## 2 Architectural Overview

WorldGuard is a software isolation solution with hardware enforcement. WorldGuard provides software execution contexts known as "worlds", beyond which software cannot reach. Software isolation is achieved by restricting a world’s access to physical addresses configured for that world, inlcuding for resources like memories or peripherals. The restrictions apply to any agents that can initiate transactions, including application processors and DMA engines. Worlds can be defined to overlap, meaning that a subset of physical addresses can be explicitly shared by multiple worlds.

A world is recognized by its World Identifier (WID). The maximum number of worlds is configurable at the hardware elaboration stage and should be determined by the number of cores and other agents, the memory space configuration, the software architecture, and other system requirements.

Accessible physical address ranges and their access rules are specified at the destination resources rather than at the transaction sources. This can simplify address range management and coordination, as it does not require run time communication and coordination among cores. It also scales naturally with the number of resources.

The WorldGuard solution does not replace the RISC‑V core Physical Memory Protection (PMP) mechanism or the Memory Management Unit (MMU), but can coexist with those mechanisms. PMP access controls are specified independently at each core and the access checks are peformed at the core, before any transaction is initiated on the bus. When the physical memory map becomes fragmented, the number of PMP entries required may exceed the number actually available, requiring more complex PMP management. Because WorldGuard address ranges and access rules are specified at the resources, WorldGuard can provide both finer granularity and better scalability than PMP. The MMU also provides some degree of isolation between software contexts, under the management of a supervisor or hypervisor. WorldGuard provides a simpler controlling code base than is required for the MMU. This simplicity reduces the size of the Trusted Computing Base (TCB).

WorldGuard is fully compatible with and does not require any modification to the RISC‑V ISA.

### 2.1 Features

The WorldGuard arhitecture provides the following salient features:

- Is architected to be available for all SiFive and RISC-V cores.
- Isolates execution contexts by using worlds, uniquely identified by the WID numeric value.
- Controls access to physical addresses.
- Provides access control on resources (memories, peripherals) for read and write accesses.
- The maximum supported number of worlds is set at the hardware elaboration stage.
- Specifies privilege mode WID CSRs in wg-aware core management by upper privilege
modes

- M-mode local WorldGuard configuration privileges, including WID changing privileges,
can be delegated to lower privilege modes.

- No privilege mode can change its own WID.
- Error interrupts are trapped in M-mode.
- Resources may be shared by multiple worlds, creating shared memory regions and shared
peripherals.

- Provides two main building blocks; wgMarkers and wgCheckers.
- Provides the concept of a trusted agent, being a core which is running with the WID autho-
rized to modify wgMarker and wgChecker control registers.

- XLEN is 32 or 64 bits
The current SiFive WorldGuard implementation:

- Provisions the trusted WID, establishing WorldGuard configuration privileges.
- Memory regions in wgChecker have sizes multiple of 4KB.
- A trusted agent can be either a dedicated core or M-mode firmware.
- Modifies caches tags for WID support.
- AXI4 and TileLink (TL) wgMarkers and wgCheckers.
- AXI4-TL and TL-AXI4 WID mapping.
- World-based debug limiting mechanisms: wg debug limiter.
- World-based trace limiting mechanisms: wg trace limiter.
### 2.2 Fundamental Concepts

The following concepts are useful in understanding the various WorldGuard components and usage models at a high level. More detail will be provided in the Architecture section.

A wg-aware core contains the WID registers needed to mark transactions with the WID associated with each active privilege level. These WID registers are accessible as CSRs.

wgMarkers are associated with transaction initiators. They add the active WID to bus transactions passing through them. A wgMarker cannot tag a bus transaction that is already tagged with a WID.

wgCheckers are associated with transaction targets. They accept or reject transactions based on a combination of the physical address being accessed, the accessing WID, and the type of transaction (read or write). Accepted transaction are passed downstream to the target resource. Rejected transactions may generate responses, but are not sent further downstream. Whether a rejected transaction generates an interrupt using a denied response is configurable and is discussed later in this document.

These blocks are detailed in Section 5.2.

The trusted WID is the WID which is authorized to access the wgMarker and wgChecker configuration registers. How the trusted WID is established is implementation specific.

A trusted agent is an initiator which marks transactions with the trusted WID. The term trusted agent can also be used to refer to the software or firmware which is running in the trusted WID.

A trusted core is a core which is configured to generate only transactions which carry the trusted WID.

Figure 1: WorldGuard Generic Block Diagram

Figure 1 summarizes the basic functioning of WorldGuard:

- The WorldGuard solution and blocks are described inside and outside the Core Complex,
using TL and AXI4 blocks. Although TL and AIX4 are used in the examples, WorldGuard can operate on any infrastructure which maintains the transaction WID.

- Behavior outside the Core Complex is system-dependent, but the same principles
apply.

- The agents (in green) are all equipped with a wgMarker that marks their outgoing transac-
tions with the active WID.

- wg-aware cores have their wgMarker within the Tile, before the L1 cache, so that the
L1 cache lines contain the WID as part of the tag.

- A trusted agent controls the wgMarkers for transactions exiting the non-wg-aware
cores.

- A trusted agent, exemplified here as a trusted core, configures the wgMarkers (in blue) and
the wgCheckers (in pink) by sending transactions marked with the trusted WID. In the

absence of a trusted core, M-mode in one or more of the wg-aware cores can be the trusted agent by using the trusted WID.

- The WID carried in a transaction is propagated through wg-aware bus interconnects (e.g.,
TL or AXI4) and blocks (e.g., L1 cache, L2 cache) until the targeted wgChecker is reached.

- Ports must propagate the WID from one bus protocol to another (e.g., from TL to
AXI4).

▪ A Front Port located at the entrance of the Core Complex may receive WIDmarked AXI4 transactions. The Front Port must map the WID to the TL protocol fields.

- AXI4 WID transport is performed using the AxUSER extension signals.
- wg-aware L1 and L2 caches contain the WID as part of the cache line tags.
- The wgChecker determines if the physical address, WID, and access type are consistent
with the rules it contains. If all match, the transaction is accepted.

- wgMarker and wgChecker configuration transactions are allowed only by the trusted
WID.

- Simple resources such as peripherals or interrupt controllers might be guarded by a
wgChecker with a simple ON/OFF strategy, with all addresses accessible by allowed WIDs.

- Complex resources such as memories may be guarded in a way equivalent to the
behavior of RISC-V core PMPs, with explicit physical address ranges being specified.

- wgCheckers can reside within the Core Complex or outside the Core Complex. The
main principle is to put them as close to the resource as possible.

- Once the wgChecker is passed, the transaction is sent without a WID to the resource.
## 3 Security Rationale and Threat Model

SiFive WorldGuard is a software isolation solution for an aggressive environment, where entities attempt to exploit software vulnerabilities to take control of execution. Typically, these exploits aim at gaining privileged access to restricted resources. The principle of protection enforced by WorldGuard is to confine all entities to their own world, thus limiting the reach of aggressive or compromised entities.

The current SiFive WorldGuard solution only considers software and non-invasive attacks. WorldGuard provides architectural limitations. Physical attacks and side channel attacks are outside the purview of WorldGuard and must be addressed separately.

The WorldGuard solution provides a system-level approach to securing access to system resources. WorldGuard scope and limitations include:

- At the system level, initial trust is considered to be limited to the following hardware/soft-
ware: The secure boot code in ROM (i.e., the ZSBL), the WorldGuard configuration code (i.e., the FSBL), and the trusted agent.

- The trusted agent can expand the trusted perimeter by including other cores. It may
also delegate some local rights on wg-aware cores. The WorldGuard gate-keeping mechanisms prevent any agent from gaining unauthorized access privileges at the system level.

- Code running on a core cannot gain more access than what is limited to its world.
PMP configuration cannot override the WorldGuard configuration. Core access to a resource must be granted first by the PMP on the core side, then by the wgChecker on the resource side.

- MMU management provides fine-grained isolation, but involves a large, complex
piece of code. Conversely, the more coarse-grained isolation provided by the World- Guard mechanism requires a very small amount of software, making it more acceptable in a Trusted Code Base (TCB).

- The trusted WID is the only WID able to configure the WorldGuard blocks (except
local configuration on cores, which are controlled by CSR access).

- It is not required that all M-mode firmware runs with the trusted WID, and so not all M-
mode firmware may have the same level of trust at the system level. For example, it may be that M-mode on only one core might execute with the trusted WID.

- It is not required that the trusted WID be limited to only M-mode firmware. It may make
sense to allocate a trusted core which utilizes the trusted WID for some or all privilege levels.

- WorldGuard does not guarantee any protection or isolation for accesses within a world.
- WorldGuard does not provide any guarantee about the functional stability and robust-
ness of applications after transactions are rejected.

## 4 Usage Models

WorldGuard can be configured to address isolation requirements in various ways. Depending on the platform architecture, the WorldGuard configuration agent (the trusted agent) might be a dedicated core which only uses the trusted WID. It might be one or more cores which change the active WID depending on the running context. Several different usage models are presented here to explore possible variations.

### 4.1 Multi-core SoC with Trusted Core

A high level of security can be reached on a multi-core platform by dedicating a core to be the trusted agent. This dedicated agent is referred to as a trusted core.

In this usage model, the trusted WID is not shared with application cores. Therefore, other cores are not able to configure WorldGuard blocks. Configuring the trusted agent to run only on the trusted core prevents configuration synchronization concerns and system-wide spread of attacks.

This kind of platform is usually complex and hosts several agents, like DMA, cryptographic blocks, and many peripherals and memories. It is likely identified as requiring a very high level of security. On some platforms, the dedicated core may be responsible for other security related tasks (behaving as a Secure Element) and power management related tasks (acting as a Power Management Controller).

Figure 2: Multi-core SoC with Trusted Core

Locally to the core, the M-mode firmware can delegate some rights to lower modes. These local configurations are performed through dedicated CSRs.

### 4.2 Multi-core with M-mode Firmware as Trusted Agent

In this model, the initial configuration setup grants one or more wg-aware cores the right to use the trusted WID. This allows M-mode firmware on any of those cores to change non-core wgMarker WID values and wgChecker configurations.

If multiple cores have trusted WID access, extra effort may be required to synchronize the WorldGuard configuration changes among the different cores.

Figure 3: Multi-core with M-mode Firmware as Trusted Agent

This usage model corresponds to a Linux server scenario, as depicted in Figure 4. There are two worlds operating in the software stack, one world for M-mode firmware and one world for the upper layers, including S-mode and U-mode managed by the Linux kernel.

The platform hosts M-mode firmware, which sets the WorldGuard configuration and runs the SBI firmware. The WorldGuard configuration is independent of the Linux kernel and Linux user tasks.

Isolation between user tasks is managed by the kernel using an MMU, without any change from a vanilla Linux kernel.

The WorldGuard solution transparently interoperates with the OS functionality and there is no configuration of any WorldGuard blocks by the Linux kernel.

Figure 4: Platform Running Linux on WG-aware Cores

A derived usage model is a platform supporting the hypervisor privilege mode (HS-mode), as depicted in Figure 5. In this case, a type-1 hypervisor can operate on top of the M-mode secure monitor. Each guest container (VM) accesses S- and U-mode only and is not aware of World- Guard; there is no configuration of any WorldGuard blocks by any container software.

Each guest container managed by the hypervisor could run in a distinct world. The limited number of WIDs available in the implementation necessarily limits the number of guest containers that can be assigned unique WIDs.

Figure 5: Hypervisor Architecture with WorldGuard

### 4.3 Single Core

On a platform with a single core, M-mode firmware is considered the trusted agent.

M-mode firmware is able to access the core WorldGuard configuration via the core CSRs. Mmode firmware operating under the trusted WID is able to configure other agents' wgMarker WID values and the wgChecker configurations.

Figure 6: Single-core with M-mode Firmware as Trusted Agent

The first configuration in the single core usage model is the RTOS scenario. In this scenario (see Figure 7), an RTOS running in either M-mode or S-mode manages different tasks in Umode, and uses the WorldGuard mechanisms for improved task isolation. In the extreme case, every U-mode task is assigned to a different world. Even though the core PMP can also play this role, some implementations find benefit in using the WorldGuard mechanism; a large fragmentation of protected resources can consume or require too many PMP entries while the WorldGuard configuration is more scalable.

Figure 7: RTOS Architecture with WorldGuard

This single-core usage model fits well with the REE/TEE software architecture, shown in Figure 8.

Figure 8: REE/TEE Software Architecture

The TrustZone™ architecture defines two worlds, one being trusted and secure and the other being untrusted and non-secure, or at least not trusted enough to access assets handled by the trusted world. Furthermore, the secure world or Trusted Execution Environment (TEE) contains different applications that are supposed to be isolated from each other. This architecture relies on secure monitor firmware for the switch between secure and non-secure worlds.

The use of WorldGuard for this architecture leads to distinct worlds for the Rich Execution Environment (REE) and the TEE. The simplest implementation is a two world solution; the trusted

WID is used for the secure world for the secure monitor and the TEE software (OS and trusted applications), while the other WID is used for the non-secure world for the REE software (OS and tasks).

If finer isolation is required, more worlds can be used. The TEE OS can run in its own world and each of the trusted applications can use a distinct world. An alternative way of isolating the trusted applications from each other is to use the MMU.

Figure 9 illustrates how a WorldGuard platform can address an REE/TEE architecture. The switch between different worlds in supervisor mode is managed by the secure monitor while the switch between different user-mode apps can be delegated to either the Rich OS or the trusted kernel in the appropriate world.

Figure 9: REE/TEE Architecture with WorldGuard

Note that this figure shows different worlds for even the untrusted user-mode applications (i.e., tasks). This scenario only applies if the Rich OS supports WorldGuard integration. This is something easily achievable with an RTOS (e.g., freeRTOS). However, it is highly complicated in terms of the effort required to modify the codebase for a large OS (e.g., Linux). It also does not make a lot of sense considering the large codebase size of the Linux OS, and so contradicts the security-through-simplicity objectives of WorldGuard-supporting software.

The availability of the hypervisor is not required for this architecture.

Note

This REE/TEE architecture applies to multi-core platforms as well and it is only described in the single-core model for simplicity.

Beyond this secure/non-secure dual architecture, an example of a multi-level security architecture is the Keystone Enclave Architecture (see [3]), as depicted in Figure 10. This architecture considers on one side an untrusted world, typically a Linux or any other rich OS-based software container, plus one or more separate secure enclaves. In terms of versatility, the WorldGuard solution fits in well with the Keystone objectives.

Figure 10: Keystone Architecture with WorldGuard

### 4.4 Debug

The usage models described in the previous sections demonstrate the need for strong software isolation. This isolation is often related to the coexistence of different stakeholders on the same shared platform. This coexistence is present throughout the SoC life cycle, including in the development stages. Therefore, the debug services that may be associated with some of the worlds must be considered in the WorldGuard context, which means the debug services must not be able to provide access to some assets that WorldGuard protects. SiFive utilizes a World- Guard debug limiter to address these use cases.

The first use case is the REE/TEE configuration (see Figure 11). While it may happen that the TEE requires some development and debug services during the early stages of the software development life cycle, the usual debug context is about debugging the REE side (OS, applications). This ability to debug the REE must not be a way to access to the assets available in the TEE.

Figure 11: Debug on REE/TEE Platform

A similar use case is the hypervisor configuration (see Figure 12). A platform running a hypervisor typically uses virtual machines. These virtual machines (VMs) must be isolated from each other, such as by using WorldGuard. The life cycle of a VM may require some development and debug operations on the platform. These operations must not imply a loss of isolation with the other VMs and leakage of assets available in the other VMs.

Figure 12: Debug on Hypervisor Platform

More complex use cases require the debug ability on the Core Complex and more generally on the platform to be managed by an external entity, such as a provisioning manager. This implies that debug control cannot be solely controlled by the (secure) boot code.

### 4.5 Bypass

On a platform equipped with WorldGuard, the software/product architect may not want to use the isolation mechanisms. The rationale can be to share one platform among different use cases/SKUs, including some not requiring software isolation, or it can be a transient situation of having to use the platform before defining the isolation configuration.

The bypass use case would be to have a simple, static configuration where only one world is defined and encompasses all agents and resources. Therefore, any marked request is accepted by the wgCheckers and granted access. In this scenario, WorldGuard cannot detect any illegal accesses, and only software or other mechanisms can detect any violations.

It is recommended to lock such a configuration once completed. In bypass mode, all privilege modes (M, S, U) will use the trusted, M-mode WID, and thus their accesses will not be prevented by WorldGuard.

## 5 Architecture and Implementation Details

This section describes the WorldGuard architecture in more detail and uses some implementation details to provide examples.

A primary principle of the WorldGuard architecture is that requests are marked at the agent side and checked at the resource side. The value the requests are marked with is determined by the wgMarker WID register. The rules for checking are determined by wgChecker settings.

wgMarker and wgChecker configurations are accessible only by requests marked with the trusted WID. Core-local wgMarkers which are accessed via CSRs can be also configured by Mmode software.

### 5.1 WID Representation

The overall number of worlds is NWorlds, ranging from 0 to NWorlds-1.

The trusted WID value is used for granting access to the WorldGuard block configuration registers. How the trusted WID is established is implementation specific. Current SiFive implementations utilize the value NWorlds-1 as the trusted WID.

WIDs are represented in two different formats, depending on usage:

- The real numeric value, encoded in binary format and requiring log2NWorlds bits, for sin-
gle value selection. For example, WID 3 would be represented as 0x3 or 0b0011.

- The bitmask value, requiring NWorlds bits, for multiple values selection. If NWorlds is less
than the register length (i.e., XLEN), the remaining bits are reserved for future use (RFU) and set to 0. For example, WID 3 would be represented as 0b1000.

### 5.2 Hardware Blocks

The hardware blocks described in this section are located both in and out of the Core Complex. This section describes the WorldGuard blocks:

- CSRs in the wg-aware cores for managing the core WID values.
- wgMarkers tag new requests with the WID value.
- wgCheckers validate accessibility to resources for marked requests.
The CSRs and the core wgMarker are integrated into wg-aware cores. Agent wgMarkers and the wgCheckers are integrated into non-core IP. They are memory-mapped and their control register access is filtered by the trusted WID. By default, none of the other WIDs can modify any of the control registers.

In the following sections, descriptions related to WorldGuard blocks over TileLink (TL) are also applicable to WorldGuard blocks over AXI4, except when otherwise noted.

```text
5.2.1   Input Values
```

Input values, such as from straps or one time programmable values, provide the following static information:

- mwid defines the WID value for M-mode on the core. It is independent per core, so poten-
tially different per core.

- mwidlist defines the authorized WID values on the core for privilege levels lower than M-
mode. This list is independent per core, so potentially different per core. Up to NWorlds worlds may be authorized. mwidlist may be hardwired or connected to a boot-time-programmable register. It is provided to the core as wired inputs, similar to the reset vector. Bit position 0 represents WID 0, bit position 1 represents WID 1, and so on up to bit position N-1, which represents WID NWorlds-1. When a bit in the register is set, the corresponding WID is enabled for use.

- The worlds authorized for debug via the debug limiter.
- The worlds authorized for trace via the trace limiter.
The input signals must be connected at the integration stage of the Core Complex. These input signals are sampled into registers at each Core Complex reset.

```text
5.2.2   wgMarkers
```

A wgMarker is attached between an agent and a bus. It tags all bus transactions from the agent. wgMarkers for TL use the TL userField to carry the WID. wgMarkers for AXI4 use the AXI4 AxUSER signals to carry the WID.

A wgMarker has in and out ports, plus wires or a control port for configuration.

A wgMarker cannot modify transactions that are already marked with a WID.

There are two categories of agents:

- Non-wg-aware agents, including non-wg-aware cores. These agents use the configured
WID for all transactions.

- wg-aware agents. These agents are able to select the appropriate WID for the context. wg-
aware cores can use the WID for the active privilege mode.

```text
5.2.2.1    wgMarkers for Non-wg-aware Agents
```

For cores and other agents that are not wg-aware, the only way to access the wgMarker configuration is via a memory-mapped register. Configuration is accessible only by requests marked with the trusted WID. How the wgMarker is configured with the trusted WID information is implementation dependent.

The configuration register contains the following fields:

- The wid values dictates the WID included in transactions.
- The valid bit in the wgMarker register indicates whether the wgMarker is enabled. If the
valid bit is not set, transactions are not marked and not sent to the bus.

- The lock bit prevents further changes to the wgMarker configuration. If the lock bit is
clear, all the configuration fields can be changed. If the lock bit is set, none of the configuration fields be changed until the next platform reset.

There are as many wgMarkers as there are non-core agents.

Note

WID changes on a non-wg-aware core must be performed in a specific sequence in order to avoid an exception during the WID switch operation. The details of that are beyond the scope of this paper.

```text
5.2.2.2    wgMarkers for wg-aware Agents
```

If the wgMarker is integrated within a wg-aware core, there is a WID value associated with each privilege mode. The WID value to be placed into the transaction is retrieved from the approprite WID register, depending on the privilege mode (see Section 5.2.2.3):

- mwid defines the M-mode WID for the core.
- mlwid defines the WID for the next lower privilege mode below M-mode.
- slwid defines the WID for the next lower privilege mode below S-mode (i.e., U, VS, VU).
WorldGuard does not allow a privilege mode to change its own WID. Only a higher privilege mode can set a WID CSR. The WID of M-mode on a core is set by the external environment and does not change between resets.

mwidlist limits the WID values available to privilege modes lower than M-mode. A core WID value can only be set to one of the WID values enabled in mwidlist. Attempts to write a core WID value which is not enabled in mwidlist result in a legal value being substituted (WARL). mwidlist is an input value to the core; see section Section 5.2.1. This list cannot be changed after reset.

mwidlist is not directly visible to software. However, M-mode software can discover which WIDs are enabled in mwidlist by leveraging the fact that the mlwid CSR is Write-Any-Read- Legal (WARL). Software can attempt to write a WID value to mlwid, then read mlwid back to see if the write succeeded.

```text
5.2.2.3    WID CSRs
```

Table 1 describes the CSRs used to control WID values in wg-aware cores.

By default, only M-mode firmware can configure the WID CSRs. A delegation mechanism is provided to allow a lower privilege mode to configure certain WID CSRs. The purpose of delegation is to allow privilege mode X to delegate to privilege mode X-1 the right to set the WID value in the [X-2]wid CSR.

Table 1: WID CSRs

```text
   Size                              Reset
                Name       Access                                 Description
  (bits)                             Value
 XLEN          mlwid       RW for     0x0      WID value for the next lower privilege mode
                            M-                 below M-mode. The value is in binary encoding;
                           mode                Ceil(Log2NWorlds) LSBs are used, others are
```

zero.

```text
 XLEN          slwid       RW for     0x0      WID value for the next lower privilege mode
                           S-mode              below [H]S-mode. The value is in binary encod-
                                               ing; Ceil(Log2NWorlds) LSBs are used, others
```

are zero.

```text
 XLEN          mwiddeleg   RW for     0x0      The set of WID values delegated to [H]S-mode,
                            M-                 represented as a bitmask. NWorlds LSBs are
                           mode                used, others are zero.
```

Note on the use of these registers in processors with different processor mode support:

- For M-mode only cores, there is no WID CSR. The M-mode value is set by mwid. There is
no notion of delegation because there are no lower privilege modes.

- For M/U cores, there is only the mlwid CSR. It is used by M-mode firmware to set the U-
mode WID value. There is no delegation CSR.

- For M/S/U cores, the mlwid and slwid CSRs are present. One CSR is also dedicated for
delegation, the XLEN-bit mwiddeleg CSR, which represents delegation from M-mode to S-

mode. The typical use case is to have M-mode (e.g., the secure monitor) delegate to Smode (e.g., the RTOS) the ability to set the WID for U-mode (e.g., user tasks). The delegation CSRs are not visible from the delegatee. If S-mode software needs to determine which WID values it has been delegated, it can use the fact that the slwid is a WARL register; it writes a value to slwid, then reads slwid to see if the written value is read back.

- For M/HS/VS/VU cores, the mlwid and slwid CSRs are present. One CSR is also dedi-
cated to the delegation, the XLEN-bit mwiddeleg CSR, which represents the delegation from M-mode to HS-mode. The typical use case is to have M-mode (e.g., the secure monitor) delegate to HS-mode (e.g., the type-1 hypervisor) the ability to set the WID for the different containers (e.g., the virtual machines). VS-mode (the guest OS) and VU-mode (user tasks) are both handled by slwid. If HS-mode software needs to determine which WID values it has been delegated, it can use the fact that the slwid is a WARL register; it writes a value to slwid, then reads slwid to see if the written value is read back.

Note

It may happen that a software architecture wants to run in an M/U configuration, e.g. a Mmode microkernel with U-mode tasks and drivers, while running on an M/S/U platform. This achieved by "ignoring" the S-mode. Setting the U-mode WID from M-mode can be done by directly configuring the slwid register from M-mode firmware, but mwiddeleg must be set with the U-mode WID values.

```text
5.2.2.4    WID Delegation Example
```

Consider a platform with a core with M/S/U modes, NWorlds=8, and trusted WID=7. The software architecture is a secure monitor running in M-mode, an RTOS in S-mode, and user tasks in U-mode. Configuration is performed in order as follows:

1. The mwidlist input wires specify the worlds that can run in S- and U-modes as {0,1,2,3,4,5,6}. 2. The mwid input wires set the M-mode WID as the value 7. This establishes M-mode as a trusted agent. 3. At reset, mwiddeleg is set by hardware to 0; thus slwid is not accessible 4. M-mode software sets mlwid to 0, indicating the RTOS is WID 0. 5. M-mode software sets mwiddeleg bits {1,2,3,4,5,6} to enable WID values that S-mode software can assign to U-mode via slwid. 6. Hardware sets slwid to 1 because it is the lowest legal value as defined in mwiddeleg.

The result is that:

1. M-mode firmware runs in WID 7.

2. S-mode RTOS runs in WID 0. 3. U-mode tasks can be run in WIDs {1,2,3,4,5,6}. 4. The RTOS is able to change the slwid value among the values {1,2,3,4,5,6}, as all these values are in mwiddeleg.

```text
5.2.2.5   wgMarker Value Computation
```

A core wgMarker must be designed into the core complex tile in order to process outgoing transactions and mark them with a WID value. The WID value is inherited from the CSRs based on the privilege mode. The following figures provide a visual depiction of the CSRs described above and their integration in the core.

- For M-only cores, only the M-mode WID is used by the marker:
Figure 13: WorldGuard M-mode only core Marker WID selection

- For M/U cores, the marker selects the appropriate WID based on the active privilege mode:
Figure 14: WorldGuard M/U core Marker WID selection

- For M/S/U cores, the marker selects the appropriate WID based on the active privilege
mode, with S-mode setting slwid:

Figure 15: WorldGuard M/S/U core Marker WID selection

- For M/HS/VS/VU cores, the selection is the same as above, except slwid is set by HS-
mode.

Figure 16: WorldGuard M/HS/VS/VU core Marker WID selection

```text
5.2.3   wgCheckers
```

wgCheckers are used to control access to resources. They analyze marked transactions and either grant or deny access based on configured rules. The wgCheckers are used to filter the requests sent from an agent before transferring the request to the targeted resource. Analysis is based on the target address, the WID value, and the access type (Read, Write). wgChecker configuration registers, named slots, define the access rules. Configuration of the wgChecker slots is done using memory-mapped accesses from the trusted WID.

If any rule matches the request, the access is granted and the request is passed to the resource.

If no rules match the request, the request is denied and the following actions occur:

- The wgChecker error registers are set with the rejected transaction fields; the WID, the
access type, and the address.

- A denied response may optionally be sent back to the requester.
- An interrupt may optionally be triggered.
Triggering a denied response and/or an interrupt is configurable in the wgChecker. Not triggering an interrupt is important in the case of a speculative instruction fetch that could have performed an illegal access.

The number of wgChecker slots is implementation dependent, and varies based on the requirements of the specific checker.

A rule consists of a physical address range, a list of WIDs that have access to this range, and the authorized access type (R, W) for the WIDs in the list.

In the case of rejected transactions, the responses are:

- Reads return zeroed payloads, and may optionally respond with denied.
- Writes are acknowledged (there is no denied response), but are not sent downstream to
the resource.

- Atomic Operations (AMO) return zeroed payload, but are otherwise ignored.
- Cache Management Operations (CMO) are acknowledged, but are otherwise ignored.
wgChecker interrupts can be masked by whatever interrupt controller they are attached to.

The wgChecker block is similar to a RISC-V core PMP as defined in [1], but the slots defining the memory ranges also contain the authorized WID values and access attributes.

The wgChecker address ranges defined in the slots may overlap.

```text
5.2.3.1    Interrupts and Error Registers
```

In the case of an access violation, it is possible to send an denied notification and to generate an interrupt signal.

The wgChecker is also connected as an interrupt source to the interrupt controller, which can be the PLIC, the Core-Local Interrupt Controller (CLIC), or any other interrupt controller. As a good practice, it is used to notify the trusted agent, if the trusted agent is registered for this interrupt.

If a trusted core is present, the global interrupt on the Platform-Level Interrupt Controller (PLIC) must be set to trigger an interrupt to the trusted core. This global interrupt has a lower precision than the local interrupt.

Every wgChecker contains error registers. These memory-mapped registers are accessible only by the trusted WID, which can examine the wgChecker for errors. If the interrupt handler needs the error information, it must obtain the information via a trusted agent.

```text
5.2.4   Enabling and Locking Policies
```

wgMarkers and wgChecker rules can be disabled/enabled:

- If a wgMarker is disabled, no transaction is marked or transmitted.
- If a wgChecker slot is disabled, this slot is not used for checking the incoming marked
transactions.

- Enabling and disabling cannot be performed if the lock is set.
The wgMarker and wgChecker configurations can be locked after initial configuration or kept open for re-configuration by the trusted agent. Any block or register can be locked by the trusted agent at any time. If locked, there is no way, even for the trusted agent, to modify the slot until the next block reset.

### 5.3 Software Configuration and Usage

Summarizing earlier statements:

- The M-mode WID is set by input parameters and cannot be changed by software.
- WID setting in a non-wg-aware core is managed by the trusted agent.
- WID setting in wg-aware cores is done via local core CSRs. Accessibility depends on the
privilege mode and the values of mwidlist and mwiddeleg.

- No privilege mode can change its own WID value.
- Non-CSR WorldGuard block configuration registers are memory-mapped and are accessi-
ble only by the trusted WID. Any software able to run in the trusted WID can access and modify these registers.

```text
5.3.1   Default Configuration
```

After reset, M-mode firmware starts by running in the world specified by mwid.

Note that at least one wg-aware core wgMarker must be set to the trusted WID. The corresponding WID must be set in mwidlist only if that WID will be used in mlwid or slwid.

```text
5.3.2   Secure Boot Process and Initial WorldGuard Configuration
```

As the inital WorldGuard configuration is highly critical for platform asset management, the secure boot process is used to set the initial WorldGuard configuration in trusted conditions .

Secure boot code in ROM is assumed as the Root of Trust (RoT).

Upon release from reset, all cores jump to the ROM. After completion of any setup and RoT tasks, execution of the secure boot code begins with the First Stage Boot Loader (FSBL). In the case of a dedicated trusted core, the trusted core is responsible for secure boot operation. In usage models without a trusted core, it can be any of the cores that are assigned the trusted WID as the M-mode WID value. This core is then considered the trusted agent.

Secure boot code execution in ROM completes by authenticating the FSBL. The potential complexities and flexibility requirements suggest using the FSBL for managing the WorldGuard configuration, rather than immutable ROM code. The FSBL determines where the WorldGuard configuration is located, e.g., at a hardcoded address or an address stored in One Time Programmable (OTP) fuses.

The FSBL can interpret the WorldGuard configuration information and set all the WorldGuard blocks appropriately. Once this configuration is set, potentially including locks, the FSBL wakes up the other cores and application software execution can begin.

## 6 Error Management

This section describes error management in both data and instructions accesses and considers the specific case of speculative accesses.

### 6.1 Incorrect CSR Usage

Some errors cases considered when using a CSR:

- Trying to access a non-existing CSR or violating the CSR access rules raises an exception.
- Setting an incorrect WID in a CSR constrained by a WID list results in setting a legal value
from this WID list (WARL register). Current SiFive implementations use the lowest valid WID.

### 6.2 Speculative Accesses

When speculative accesses are performed, it may be that speculatively accessed addresses do not belong to the active world, so the attempted access is illegal. This illegal access will be prevented by the wgChecker and must be ignored, as it is not an intentional access by software but only a consequence of microarchitectural speculative fetches.

For instruction access requests, the wgChecker returns the instruction to the core as zero. As this zero instruction is ultimately not executed, there is no resulting exception.

For data access requests, the wgChecker returns the data as zero. This zeroed value may not be detected by software as invalid because a zero value may be a legal value. For this reason, it is recommended to use source side control mechanisms such as the PMP or the MMU for detecting and controlling these kinds of errors.

In this way, speculative accesses are safe with respect to WorldGuard.

## 7 WorldGuard Impact on Other Hardware

Blocks

Several hardware blocks on the platform may be impacted by WorldGuard. This is usually because these hardware blocks had not previously considered isolation requirements. Therefore, their generic implementation and use "as is" does not comply with the WorldGuard security rationale due to a lack of access control.

There are two types of consequences:

- There is no requirement for any modification on the block, but some specific software
process is required at WID value configuration change.

- These hardware blocks must be modified or be equipped with a wgChecker on their config-
uration interface.

Simple descriptions of such considerations are given here as an overview. These sections also consider some representative hardware blocks that are not impacted by the WorldGuard solution.

### 7.1 Caches

Caches are part of the data path. Therefore, caches must be wg-aware and include the WID in the cache line metadata.

In current SiFive implementations, the WID is stored with each cached line and checked against the transaction WID. If the addresses match but the WIDs do not, then the line is evicted and the request is handled as a cache miss.

An illegal access of memory leads to denied, and the response that comes back has a zeroed payload. This response is stored in the cache with the transaction WID value and a zero line. If the line is dirtied in the cache, the eviction write back will be ignored.

Some caches may have a configuration interface (e.g., way locking, Loosely Integrated Memory configuration). This configuration interface must be protected by a wgChecker in order to filter the configuration requests based on the authorized WIDs.

If the cache is not made wg-aware, then the WID check must be performed on the path from the core to the cache.

### 7.2 Tightly-Integrated Memory (TIM)

A Tightly-Integrated Memory (TIM) may be instantiated close to a core. The TIM grants fast local access with the core, but the TIM may also be accessible by other cores via the bus fabric. Controls must be set for these two kinds of accesses. On local accesses, the core PMP can play the access rights controller role. On remote accesses, a wgChecker can filter the authorized WIDs.

### 7.3 Bus Fabric

On TileLink (TL) buses, there is no modification required for WorldGuard. The WID is transmitted using the existing userField field. The WID is propagated with the transaction through TileLink to the target resource.

On AXI4 bus protocols, the AxUSER signals are used for WID transport.

### 7.4 CLIC/PLIC

The Core-Local Interruptor (CLINT) and CLIC contain an mtimecmp register that is used for comparison with mtime for time-based interrupts. Typically, the software sets the value of mtimecmp with the value mtime ticks where the ticks value is the duration of the task to be interrupted. When mtime reaches this value, the interrupt will trigger.

The security issue is that the mtimecmp register for one core can be configured by another core. WorldGuard protects access to the CLINT and the CLIC by adding a single-slot wgChecker that filters the mtimecmp register accesses based on the WID values corresponding to authorized cores.

### 7.5 Debug and Trace

If required, debug and trace mechanisms must be prevented from accessing certain worlds.

This scenario is typical of a software architecture where some portions of the code, for example the TEE or the secure enclave, are not accessible to the application developer and so must not be available for debug or trace, while the application that is currently being debugged must be accessible. For that purpose, WorldGuard solution allows the debug limiter and the trace limiter mechanisms, which control access based on WID.

```text
7.5.1   Debug Security Level
```

Beyond WID control, there is no limitation to the debug features. It is therefore strongly recommended to use the secure debug mechanism (contact SiFive for more information) to control system-level debug activation.

More aggressive options could consist of having a DBG_DISABLE input to disable debug functionality when set. This input can be connected to a fuse or a debug authentication signal.

### 7.6 System Bus Access (SBA)

System Bus Access (SBA) implements a bus agent that connects with the bus fabric to allow access to the device’s physical address space without involving a core to perform accesses.

SBA behaves like a DMA agent in that it can read or write any memory accessible to the Core Complex. Without any control, it can have full access.

The recommended approach is to provide SBA with a wgMarker. The wgMarker WID value is a specific value independent of those used by the cores and not necessarily common to any of the other worlds. The wgCheckers determine what the SBA can access, independently of what software running on the cores can access. For example, an SBA can be used to monitor portions of memory not addressable by software running on the cores.

## 8 References

[1] RISC-V Privilege Specification, Available: https://riscv.org/technical/specifications/

[2] RISC-V Debug Specification, Available: https://riscv.org/technical/specifications/

[3] Keystone Enclave Architecture, Available: https://keystone-enclave.org/
