
import boto3
import os
import zipfile
import sys
import shutil

def verbose_print(msg):
    print(f"[INFO] {msg}")

def error_exit(msg):
    print(f"[ERROR] {msg}")
    sys.exit(1)

gamelift_client = None

try:
    gamelift_client = boto3.client('gamelift', region_name='us-east-1')
    verbose_print("Connected to GameLift successfully.")
except Exception as e:
    error_exit(f"Failed to connect to GameLift: {e}")

def delete_all_game_lift_builds():
    try:
        # List all builds
        response = gamelift_client.list_builds()

        # Check if there are any builds to delete
        if 'Builds' in response:
            builds = response['Builds']

            # Iterate through each build and delete it
            for build in builds:
                build_id = build['BuildId']
                print(f"Deleting build with ID: {build_id}")
                gamelift_client.delete_build(BuildId=build_id)

            print("All builds have been deleted.")
        else:
            print("No builds found in GameLift.")
    except Exception as e:
        error_exit(f"Error deleting builds: {e}")


delete_all_game_lift_builds()