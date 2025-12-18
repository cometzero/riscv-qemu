import re
import sys

def prettify_dts(dts_path):
    with open(dts_path, 'r') as f:
        content = f.read()

    # 1. Null-terminated strings
    def repl_null(match):
        s = match.group(1)
        return '"' + s.replace('\\0', '", "') + '"'
    content = re.sub(r'"([^"]*\\0[^"]*)"', repl_null, content)

    # 2. ISA check (split long line)
    def repl_isa(match):
        pre = match.group(1)
        # remove surrounding quotes and split
        raw = match.group(2).replace('"', '')
        parts = raw.split(', ')
        # re-assemble with wrapping
        # 5 items per line
        lines = []
        curr = []
        for p in parts:
            curr.append(f'"{p}"')
            if len(curr) >= 5:
                lines.append(', '.join(curr))
                curr = []
        if curr:
            lines.append(', '.join(curr))
        
        joined = ',\n\t\t\t\t'.join(lines)
        return f'{pre}{joined}'

    content = re.sub(r'(riscv,isa-extensions = )(.*);', repl_isa, content)

    # 3. Add node labels (safe ones)
    content = re.sub(r'cpu@0\s*\{', 'cpu0: cpu@0 {', content)
    content = re.sub(r'cpu@1\s*\{', 'cpu1: cpu@1 {', content)
    content = re.sub(r'plic@c000000\s*\{', 'plic: plic@c000000 {', content)
    content = re.sub(r'clint@2000000\s*\{', 'clint: clint@2000000 {', content)
    content = re.sub(r'test@100000\s*\{', 'test: test@100000 {', content)
    content = re.sub(r'pci@30000000\s*\{', 'pci: pci@30000000 {', content)
    
    # 4. Handle CPU interrupt controllers
    # This requires stateful processing or regex with lookahead?
    # Simple replace with known structure context
    # cpu@0 -> interrupt-controller -> cpu0_intc
    # We'll just replace contextually
    
    # Split by logic blocks using known indentation
    lines = content.splitlines()
    new_lines = []
    cpu0_context = False
    cpu1_context = False
    
    for line in lines:
        if 'cpu0: cpu@0 {' in line:
            cpu0_context = True
        elif 'cpu1: cpu@1 {' in line:
            cpu1_context = True
        elif line.strip() == '};':
            cpu0_context = False
            cpu1_context = False
            
        if 'interrupt-controller {' in line:
            if cpu0_context:
                line = line.replace('interrupt-controller {', 'cpu0_intc: interrupt-controller {')
            elif cpu1_context:
                line = line.replace('interrupt-controller {', 'cpu1_intc: interrupt-controller {')
        
        new_lines.append(line)
    
    content = '\n'.join(new_lines)
    
    # 5. Safe reference replacements
    # Only replace specific phandle usages
    
    # interrupt-parent = <0x05>; -> <&plic>;
    content = content.replace('interrupt-parent = <0x05>;', 'interrupt-parent = <&plic>;')
    
    # cpu = <0x03>; -> <&cpu0>; (in cpu-map)
    content = content.replace('cpu = <0x03>;', 'cpu = <&cpu0>;')
    content = content.replace('cpu = <0x01>;', 'cpu = <&cpu1>;')
    
    # interrupts-extended
    # 0x04 -> &cpu0_intc
    # 0x02 -> &cpu1_intc
    # Only inside interrupts-extended property
    # Because <0x04> could be elsewhere
    
    def repl_int_ext(match):
        val = match.group(1)
        # Repalce phandles
        val = val.replace('0x04', '&cpu0_intc')
        val = val.replace('0x02', '&cpu1_intc')
        return f'interrupts-extended = <{val}>;'
        
    content = re.sub(r'interrupts-extended = <([^>]+)>;', repl_int_ext, content)
    
    # PCI interrupt-map
    # plic is 0x05 -> &plic
    # cpu0_intc is 0x04 -> &cpu0_intc
    # cpu1_intc is 0x02 -> &cpu1_intc
    # cpu0 is 0x03 -> &cpu0
    # cpu1 is 0x01 -> &cpu1
    
    def repl_int_map(match):
        val = match.group(1)
        val = val.replace('0x05', '&plic')
        val = val.replace('0x04', '&cpu0_intc')
        val = val.replace('0x02', '&cpu1_intc')
        val = val.replace('0x03', '&cpu0')
        val = val.replace('0x01', '&cpu1')
        return f'interrupt-map = <{val}>;'

    content = re.sub(r'interrupt-map = <([^>]+)>;', repl_int_map, content)

    # Clean up phandle definitions
    # remove lines "phandle = <0x..>;" 
    # BUT only if we are sure we replaced all refs. 
    # For safety, let's COMMENT them out instead of deleting, or just delete specific ones we know we handled.
    # cpu0(03), cpu1(01), cpu0_intc(04), cpu1_intc(02), plic(05)
    
    known_phandles = ['0x01', '0x02', '0x03', '0x04', '0x05', '0x06']
    for p in known_phandles:
        content = re.sub(f'\s*phandle = <{p}>;', '', content)

    with open(dts_path, 'w') as f:
        f.write(content)

if __name__ == '__main__':
    prettify_dts(sys.argv[1])
