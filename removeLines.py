def remove_empty_lines(file_path):
    # Read the Solidity file
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Remove empty lines
    non_empty_lines = [line for line in lines if line.strip()]

    # Write the cleaned content back to the file
    with open(file_path, 'w') as file:
        file.writelines(non_empty_lines)

    print(f"Empty lines removed from {file_path}")

# Usage
file_path = r'D:\blockchain\energy_transaction\Smart-Contract-for-P2P-Energy-Trading-in-a-Blockchain-platform\Peer-to-peerEnergy.sol'
remove_empty_lines(file_path)
