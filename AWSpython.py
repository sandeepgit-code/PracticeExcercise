import json
import boto3
import copy

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')
    
    ec2_resource = boto3.resource('ec2')
    instances = ec2_resource.instances.all()
    
    instance_data = {}
    for instance in instances:
        instance_name = ''
        instance_tags = instance.tags
        
        for instance_tag in instance_tags:
            if instance_tag['Key'] == 'Name':
                instance_name = instance_tag['Value']
        
        instance_data['name'] = instance_name
        instance_data['security_groups'] = []
        
        security_group_ids = []
        for security_group in instance.security_groups:
            group_id = security_group.get('GroupId', '')
            security_group_ids.append(group_id)
        
        security_groups = ec2_client.describe_security_groups(GroupIds=security_group_ids)
        for security_group in security_groups['SecurityGroups']:
            ip_permissions = security_group.get('IpPermissions', [])
            
            for ip_permission in ip_permissions:
                instance_security_group = {}
                from_port = ip_permission.get('FromPort', '')
                to_port = ip_permission.get('ToPort', '')
                ip_ranges = ip_permission.get('IpRanges', [])
                
                if from_port == to_port:
                    instance_security_group['port_range'] = str(from_port)
                else:
                    instance_security_group['port_range'] = str(from_port) + '-' + str(to_port)
                
                for ip_range in ip_ranges:
                    cidr = ip_range.get('CidrIp', '')
                    instance_security_group['source'] = cidr
                
                instance_data['security_groups'].append(copy.deepcopy(instance_security_group))
                    
            
    print(json.dumps(instance_data, indent=4))
    
    return {
        'statusCode': 200,
    }
