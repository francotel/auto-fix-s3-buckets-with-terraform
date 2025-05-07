import os
import json
import boto3
from botocore.exceptions import ClientError

# Initialize AWS clients
s3 = boto3.client('s3')
config = boto3.client('config')

# Configuration from environment variables
REQUIRE_ENCRYPTION = os.getenv('REQUIRE_ENCRYPTION', 'true') == 'true'
REQUIRE_PUBLIC_BLOCK = os.getenv('REQUIRE_PUBLIC_BLOCK', 'true') == 'true'
DRY_RUN = os.getenv('DRY_RUN', 'false') == 'true'

def check_encryption(bucket_name):
    """Check if bucket has encryption enabled"""
    try:
        s3.get_bucket_encryption(Bucket=bucket_name)
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == 'ServerSideEncryptionConfigurationNotFoundError':
            return False
        raise

def check_public_access(bucket_name):
    """Check if public access is blocked"""
    try:
        response = s3.get_public_access_block(Bucket=bucket_name)
        settings = response['PublicAccessBlockConfiguration']
        return all(settings.values())
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchPublicAccessBlockConfiguration':
            return False
        raise

def fix_encryption(bucket_name):
    """Enable default encryption for bucket"""
    if DRY_RUN:
        print(f"[DRY RUN] Would enable encryption for {bucket_name}")
        return True
        
    s3.put_bucket_encryption(
        Bucket=bucket_name,
        ServerSideEncryptionConfiguration={
            'Rules': [{
                'ApplyServerSideEncryptionByDefault': {
                    'SSEAlgorithm': 'AES256'
                }
            }]
        }
    )
    print(f"Enabled encryption for {bucket_name}")
    return True

def fix_public_access(bucket_name):
    """Block all public access"""
    if DRY_RUN:
        print(f"[DRY RUN] Would block public access for {bucket_name}")
        return True
        
    s3.put_public_access_block(
        Bucket=bucket_name,
        PublicAccessBlockConfiguration={
            'BlockPublicAcls': True,
            'IgnorePublicAcls': True,
            'BlockPublicPolicy': True,
            'RestrictPublicBuckets': True
        }
    )
    print(f"Blocked public access for {bucket_name}")
    return True

def evaluate_bucket(bucket_name):
    """Evaluate and fix S3 bucket compliance"""
    compliance = 'COMPLIANT'
    issues = []
    
    # Check encryption
    if REQUIRE_ENCRYPTION and not check_encryption(bucket_name):
        compliance = 'NON_COMPLIANT'
        issues.append("No bucket encryption")
        fix_encryption(bucket_name)
    
    # Check public access
    if REQUIRE_PUBLIC_BLOCK and not check_public_access(bucket_name):
        compliance = 'NON_COMPLIANT'
        issues.append("Public access not blocked")
        fix_public_access(bucket_name)
    
    return compliance, "; ".join(issues) or "Compliant with all rules"

def lambda_handler(event, context):
    """Main Lambda entry point"""
    print("Received event:", json.dumps(event))
    
    try:
        # Parse the Config event
        config_item = json.loads(event['invokingEvent'])['configurationItem']
        bucket_name = config_item['resourceName']
        
        # Skip if not an S3 bucket
        if config_item['resourceType'] != 'AWS::S3::Bucket':
            return {"status": "skipped", "reason": "Not an S3 bucket"}
        
        # Evaluate compliance
        compliance, annotation = evaluate_bucket(bucket_name)
        
        # Report back to AWS Config
        if 'resultToken' in event:
            config.put_evaluations(
                Evaluations=[{
                    'ComplianceResourceType': 'AWS::S3::Bucket',
                    'ComplianceResourceId': bucket_name,
                    'ComplianceType': compliance,
                    'Annotation': annotation,
                    'OrderingTimestamp': config_item['configurationItemCaptureTime']
                }],
                ResultToken=event['resultToken']
            )
        
        return {
            "status": "success",
            "bucket": bucket_name,
            "compliance": compliance
        }
        
    except Exception as e:
        print("Error:", str(e))
        raise