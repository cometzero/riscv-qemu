import re
import sys

def hex_formatter(val):
    # Convert "0x05" -> "0x5", "0x00" -> "0x0"
    # If 0, some prefer "0", but user asked for 0xX format derived from 0x0X
    try:
        int_val = int(val, 0)
        return f"0x{int_val:x}"
    except:
        return val

def dec_formatter(val):
    # Convert "0x0a" -> "10"
    try:
        int_val = int(val, 0)
        return str(int_val)
    except:
        return val

def process_line(line):
    # Check if line has property assignment with <>
    # Allow # in property name for #address-cells etc.
    match = re.search(r'^\s*([#\w,-]+)\s*=\s*<([^>]+)>;', line)
    if not match:
        return line

    prop = match.group(1)
    values_str = match.group(2)
    
    # Split values by space, but respect existing formatting if possible
    tokens = values_str.split()
    new_tokens = []
    
    # Determine format based on property name
    is_hex_prop = prop in ['reg', 'ranges', 'dma-ranges', 'interrupt-map', 
                          'interrupt-map-mask', 'rng-seed', 'regmap', 
                          'next-addr', 'base']
    # Note: interrupt-map contains addresses and irqs. Keeping it hex is safer/cleaner.
    
    formatter = hex_formatter if is_hex_prop else dec_formatter
    
    for token in tokens:
        if token.startswith('&') or not token.startswith('0x'):
            # It's a label reference or already not hex (or simple 0)
            if token.startswith('0x'):
                # Handle cases like 0x1234 that fell through
                 new_tokens.append(formatter(token))
            elif re.match(r'^\d+$', token):
                 # It is a decimal number, apply formatter to consistency?
                 # If we want hex, convert dec to hex.
                 if is_hex_prop:
                     new_tokens.append(hex_formatter(token))
                 else:
                     new_tokens.append(token)
            else:
                new_tokens.append(token)
        else:
            new_tokens.append(formatter(token))
            
    # Reconstruct line
    # Preserve indentation
    indent = line[:line.find(prop)]
    return f"{indent}{prop} = <{' '.join(new_tokens)}>;\n"

def prettify_values(dts_path):
    with open(dts_path, 'r') as f:
        lines = f.readlines()
        
    new_lines = []
    for line in lines:
        new_lines.append(process_line(line))
        
    with open(dts_path, 'w') as f:
        f.writelines(new_lines)

if __name__ == '__main__':
    prettify_values(sys.argv[1])
