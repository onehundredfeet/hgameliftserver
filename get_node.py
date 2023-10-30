import os
import requests

#os_ext = "linux-x64"
os_ext = "darwin-x64"
def download_node_version(node_version, target_dir='node_dist'):
    """
    Download a specific Node.js version for Linux to the target directory.

    :param node_version: str, version of Node.js to download (e.g., "v20.0.0").
    :param target_dir: str, directory to store the downloaded Node.js distribution.
    """
    node_dist_name = f'node-{node_version}-{os_ext}'
    download_url = f'https://nodejs.org/dist/{node_version}/{node_dist_name}.tar.xz'

    # Create the target directory if it doesn't exist
    os.makedirs(target_dir, exist_ok=True)

    target_file_path = os.path.join(target_dir, f'{node_dist_name}.tar.xz')

    # Download the Node.js distribution
    print(f'Downloading Node.js version {node_version}...')
    response = requests.get(download_url)
    if response.status_code == 200:
        with open(target_file_path, 'wb') as file:
            file.write(response.content)
        print(f'Downloaded Node.js to {target_file_path}')
    else:
        print(f'Failed to download Node.js. Status code: {response.status_code}')

# Example usage
download_node_version('v20.9.0')
