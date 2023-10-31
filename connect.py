import boto3
import argparse
import subprocess
from botocore.exceptions import ClientError

# Initialize GameLift client
gamelift_client = boto3.client('gamelift')

def get_first_instance_id(fleet_id):
    """Retrieve the ID of the first instance in a specified GameLift fleet."""
    try:
        response = gamelift_client.describe_instances(FleetId=fleet_id, Limit=1)
        instances = response.get('Instances', [])
        if instances:
            return instances[0]['InstanceId']
        else:
            print("No instances found in the fleet.")
            return None
    except ClientError as error:
        print(f"An error occurred: {error}")
        return None

def get_compute_access(fleet_id, instance_id):
    """Request access to a compute resource."""
    try:
        response = gamelift_client.get_compute_access(FleetId=fleet_id, ComputeName=instance_id)
        return response.get('Credentials')
    except ClientError as error:
        print(f"An error occurred: {error}")
        return None

def print_env_variables(credentials):
    """Print and write AWS credentials as environment variables to a file."""
    env_commands = [
        f'export AWS_ACCESS_KEY_ID={credentials["AccessKeyId"]}',
        f'export AWS_SECRET_ACCESS_KEY={credentials["SecretAccessKey"]}',
        f'export AWS_SESSION_TOKEN={credentials["SessionToken"]}'
    ]

    with open('env.sh', 'w') as file:
        # Write a shebang line for bash
        file.write("#!/bin/bash\n\n")
        for command in env_commands:
            print(command)
            file.write(command + '\n')

    print("Environment variables written to env.sh")


def main(fleet_id):
    print(f"Getting the first instance of the fleet: {fleet_id}")
    instance_id = get_first_instance_id(fleet_id)

    if instance_id:
        print(f"Instance ID found: {instance_id}")
        credentials = get_compute_access(fleet_id, instance_id)

        if credentials:
            print("Credentials obtained:")
            print(f"Access Key ID: {credentials['AccessKeyId']}")
            print(f"Secret Access Key: {credentials['SecretAccessKey']}")
            print(f"Session Token: {credentials['SessionToken']}")
            
            # Set the credentials as environment variables in Fish shell
            print_env_variables(credentials)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Script to get access to the first instance of a GameLift fleet.")
    parser.add_argument("fleet_id", help="The ID of the GameLift fleet.")
    args = parser.parse_args()
    
    main(args.fleet_id)
