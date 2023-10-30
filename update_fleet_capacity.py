import argparse
import boto3

def update_fleet_capacity(fleet_id, desired_instances, min_size, max_size):
    """
    Update the desired capacity of a GameLift fleet.

    :param fleet_id: The ID of the GameLift fleet to update.
    :param desired_instances: The desired number of instances for the fleet.
    :param min_size: The minimum instance count for the fleet.
    :param max_size: The maximum instance count for the fleet.
    """
    try:
        gamelift_client = boto3.client('gamelift')
        response = gamelift_client.update_fleet_capacity(
            FleetId=fleet_id,
            DesiredInstances=desired_instances,
            MinSize=min_size,
            MaxSize=max_size
        )
        print(f"Fleet capacity updated successfully. New desired instances: {desired_instances}")
    except Exception as e:
        print(f"Error updating fleet capacity: {e}")

def main():
    parser = argparse.ArgumentParser(description="Update GameLift fleet capacity")
    parser.add_argument("--fleet-id", required=True, help="ID of the GameLift fleet")
    parser.add_argument("--instances", type=int, required=True, help="Desired number of instances")

    args = parser.parse_args()

    fleet_id = args.fleet_id
    desired_instances = args.instances

    update_fleet_capacity(fleet_id, desired_instances, desired_instances, desired_instances)

if __name__ == "__main__":
    main()
