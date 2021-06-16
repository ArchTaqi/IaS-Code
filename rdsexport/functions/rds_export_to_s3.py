#!/usr/bin/env python3
"""
    This utility helps to copy the monthly aws rds snapshot to the S3 bucket.
    This is to maintain the backup of rds snapshot in s3 for DR needs.
"""

import os
import sys
import boto3
import logging
from datetime import datetime, timezone, timedelta
from botocore.client import ClientError

REGION = os.getenv("REGION")
logger = logging.getLogger()
logger.setLevel(logging.INFO)
s3 = boto3.client('s3', region_name=REGION)
rds_client = boto3.client('rds', region_name=REGION)


def _create_bucket(bucket_name):
    try:
        s3.head_bucket(Bucket=bucket_name)
        return True
    except ClientError:
        s3.create_bucket(Bucket=bucket_name, CreateBucketConfiguration={'LocationConstraint': REGION})
        s3.put_bucket_encryption(Bucket=bucket_name,
        ServerSideEncryptionConfiguration={
            'Rules': [
                {
                    'ApplyServerSideEncryptionByDefault': {
                        'SSEAlgorithm': 'AES256'
                    }
                },
                ]
        })
        return True

def _get_most_current_snapshot(db_identifier, today_date):
    """
    finding most current snapshot
    return: (string) DBSnapshotInstance
    """
    snapshots = rds_client.describe_db_snapshots(SnapshotType='automated')['DBSnapshots']
    if db_identifier and not 'None':
        snapshots = filter(lambda x: db_identifier in x.get('DBInstanceIdentifier'), snapshots)

    for snapshot in snapshots:
        if snapshot['SnapshotCreateTime'].date() == today_date:
            return snapshot

def instantiate_s3_export(rds_snapshots, s3_bucket, IamRoleArn, KmsKeyId, today):
    """
    Function to invoke start_export_task using
    recent most system snapshot    Return: Response
    """
    year = today.strftime("%Y")
    month = today.strftime("%m")
    get_latest_snapshot_name,get_latest_snapshot_time = rds_snapshots['DBSnapshotIdentifier'], rds_snapshots['SnapshotCreateTime']
    return rds_client.start_export_task(
        ExportTaskIdentifier='MWP-snapshot-monthly-%s' % today.strftime("%b%Y"),
        SourceArn=rds_snapshots['DBSnapshotArn'],
        S3BucketName=s3_bucket,
        S3Prefix='{year}/{month}'.format(year=year, month=month),
        IamRoleArn=IamRoleArn,
        KmsKeyId=KmsKeyId,
        # ExportOnly=[
        #     'string',
        # ]
    )

def jsonDateTimeConverter(o):
    """To avoid TypeError: datetime.datetime(...) is not JSON serializable"""
    if isinstance(o, datetime):
        return o.__str__()

def lambda_handler(event, context):
    logger.info('start:export_snapshot')
    db_identifier = os.getenv("DB_IDENTIFIER")
    s3_bucket  = os.getenv("S3_BUCKET")
    IamRoleArn = os.environ.get('IAM_ROLE_ARN')
    KmsKeyId = os.environ.get('KMS_KEY_ID')
    today = (datetime.today()).date()
    yesterday = today - timedelta(days=1)

    snapshot = _get_most_current_snapshot(db_identifier, yesterday)

    if _create_bucket(s3_bucket):
        response = instantiate_s3_export(snapshot, s3_bucket, IamRoleArn, KmsKeyId, yesterday)
        logger.info(json.dumps(response, default=jsonDateTimeConverter))
        logger.info('end:export_snapshots')
