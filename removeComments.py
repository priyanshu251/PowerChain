import re

def remove_comments_from_sol(file_path):
    # Define regex for Solidity comments
    single_line_comment = r'//.*'
    multi_line_comment = r'/\*.*?\*/'

    # Read the Solidity file
    with open(file_path, 'r') as file:
        content = file.read()

    # Remove single-line comments
    content = re.sub(single_line_comment, '', content)

    # Remove multi-line comments
    content = re.sub(multi_line_comment, '', content, flags=re.DOTALL)

    # Write the cleaned content back to the file
    with open(file_path, 'w') as file:
        file.write(content)

    print(f"Comments removed from {file_path}")

# Usage
file_path = 'D:\\blockchain\\energy_transaction\\Smart-Contract-for-P2P-Energy-Trading-in-a-Blockchain-platform\\Peer-to-peerEnergy.sol'

remove_comments_from_sol(file_path)
