#!/usr/bin/env bash

# Script for automating cleaning up Amazon Glacier "vault".

# There are "vaults", inside each "vault" are "archives".
# ALL "archives" must be deleted PRIOR to deleting "vault".
# > Vaults can be deleted only if there are no archives in the vault as of the last inventory it computed and there have been no writes to the vault since the last inventory.

# Prerequisites (Dependencies):
# Should be installed "aws" CLI tool and setuped access by using `aws configure` (you'll need "AWS Access Key ID" & "AWS Secret Access Key").
# Should be installed "jq" tool for querying JSON files.

# Deleting an Archive in Amazon S3 Glacier:
# https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-an-archive.html
# > You can delete one archive at a time from a vault.
# > To delete the archive you must provide its archive ID in your delete request.
# > You can get the archive ID by downloading the vault inventory for the vault that contains the archive.

# Downloading a Vault Inventory in Amazon S3 Glacier:
# https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html
# > 1. Initiate an inventory retrieval job by using the Initiate Job (POST jobs) operation.
# > 2. After the job completes, download the bytes using the Get Job Output (GET output) operation.
# ^^ SHOULD BE DONE MANUALLY BEFORE USING THIS SCRIPT.

# IMPORTANT!
# "Glacier" based on TAPES archiving, so, all jobs are SLOW.
# Job with type "inventory-retrieval" - I waited ~1 day (do not know exactly how long it was taken).
# "delete-archive" subcommand - same time.

#####################################################################################################

# SET UP HERE ALL VARIABLES
AWS_ACCOUNT_ID="0123456789"
AWS_GLACIER_VAULT_NAME="some_vault_name"
AWS_GLACIER_VAULT_INVENTORY_JOB_OUTPUT_JSON_FILENAME="./some_vault_name.json"

#####################################################################################################
# DO NOT EDIT BELOW

echo "------------- Script for deletion archives from AWS Glacier vaults ------------------"
echo "Script was run with theese variables:"
echo "AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
echo "AWS_GLACIER_VAULT_NAME: $AWS_GLACIER_VAULT_NAME"
echo "AWS_GLACIER_VAULT_INVENTORY_JOB_OUTPUT_JSON_FILENAME: $AWS_GLACIER_VAULT_INVENTORY_JOB_OUTPUT_JSON_FILENAME"

# Getting info from file - how many archives inside
ARCHIVES_NUMBER=0

for ArchiveId in $(jq '.ArchiveList[] | .ArchiveId' -r "$AWS_GLACIER_VAULT_INVENTORY_JOB_OUTPUT_JSON_FILENAME"); do
  # Increase counter
  ARCHIVES_NUMBER=$((ARCHIVES_NUMBER + 1))
done

echo "Inside INVENTORY_JOB_OUTPUT_JSON file there are: $ARCHIVES_NUMBER archives."
echo ""
read -p "If it looks good, going to DELETE all archives? (y/n): " USER_INPUT

case $USER_INPUT in
n)
  echo "Pressed (n) - quit now."
  exit 0
  ;;
y)
  echo "Pressed (y), continue..."
  # just going to next steps in this script
  ;;
*)
  echo Invalid user input, exiting with error code...
  exit 1
  ;;
esac

# Getting info from file - all archives IDs - and initiate deletion each of them
CURRENT_ARCHIVE_NUMBER=1

for ArchiveId in $(jq '.ArchiveList[] | .ArchiveId' -r "$AWS_GLACIER_VAULT_INVENTORY_JOB_OUTPUT_JSON_FILENAME"); do

  echo "Initiating delete archive #$CURRENT_ARCHIVE_NUMBER with ID: '${ArchiveId}'"
  aws glacier delete-archive --account-id "$AWS_ACCOUNT_ID" --vault-name "$AWS_GLACIER_VAULT_NAME" --archive-id="${ArchiveId}"
  # There is NO any output from "aws" if there was no error
  echo "Goint to the next archive..."

  # Increase counter
  CURRENT_ARCHIVE_NUMBER=$((CURRENT_ARCHIVE_NUMBER + 1))
done

exit 0
