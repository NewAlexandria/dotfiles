#!/usr/bin/python

"""AWS EC2 SSH config Generator."""

# edit these:
# * path_to_config
# * path_to_ssh_key
# remember the path_to_config must be write-able by the script
# before running, install aws_cli and login with your credentials
# then move to your .ssh folder and in your .ssh/config file
# add an Include line like /Users/zak/.ssh/my-company-ssh-config

import boto3
import os
import pprint
pp = pprint.PrettyPrinter(indent=2)

# The location and name of our generated config file
path_to_config = '/src/work/my-company-ssh-config'

# The SSH key we use to connet to those instances
path_to_ssh_key = "/Users/zak/.ssh/keys/name-of-your.pem"

# The SSH username to use
instance_username = 'centos'

# The SSH port to connect to
ssh_port = 22


def main():
    """Main."""
    try:
        """
        Using the security credentialsa and the location we set
        when we run `$ awscli configure` we connect to AWS
        and get the list of instances on the specific location
        """
        aws_client = boto3.client('ec2')
        paginator = aws_client.get_paginator('describe_instances')
        response_iterator = paginator.paginate(
            DryRun=False,
            PaginationConfig={
                'MaxItems': 100,
                'PageSize': 10
            }
        )

        """
        Open the config file we specified to be written
        """
        ssh_config_file = open(os.path.expanduser(
            '~') + path_to_config, 'w')

        ssh_config_file.write("##########################\n")
        ssh_config_file.write("##### AWS SSH CONFIG #####\n")
        ssh_config_file.write("##########################\n\n")

        """
        We iterate the results and read the tags for each instance.
        Using those tags we create an ssh config entry for each instance.
        and append it to the config file.
        host <client>.<environment>.<name>
            Hostname <ec2-public-ip>
            IdentityFile <path_to_ssh_key>
            User <instance_username>
            port <ssh_port>
        """
        def find_tag_by_name(resv):
            for tag in resv['Tags']:
                if tag['Key'] == 'Name':
                    tag['Value']

        names = []
        for page in response_iterator:
            for reservation in page['Reservations']:
                for instance in reservation['Instances']:
                    for tag in instance['Tags']:
                        if tag['Key'] == "Name":
                            instance['iname'] = tag['Value']
            for reservation in page['Reservations']:
                sorted_instances = sorted(reservation['Instances'], key=lambda i: i['iname'])
                for instance in sorted_instances:
                    pp.pprint(instance)
                # for instance in reservation['Instances']:
                    # names.append( find_tag_by_name(instance) )
                    try:
                        host_line = ""
                        host = ""
                        env = ""
                        if 'PublicIpAddress' in instance:
                            public_ip = instance['PublicIpAddress']
                            dns = instance['PublicDnsName']
                            for tag in instance['Tags']:
                                if tag['Key'] == "Client":
                                    client = tag['Value']
                                if tag['Key'] == "Name":
                                    name = tag['Value']
                                if tag['Key'] == "Environment":
                                    env = tag['Value']

                            # pp.pprint(instance or 'none')

                            # host = "{}.{}.{}".format(
                                # client, env, name).replace(" ", "-")
                            host_line += "##########################\n"
                            host_line += "host {}\n".format(name)
                            host_line += "    Hostname {}\n".format(dns)
                            host_line += "    IdentityFile {}\n".format(
                                path_to_ssh_key)
                            host_line += "    User {}\n".format(
                                instance_username)
                            host_line += "    port {}\n".format(ssh_port)
                            host_line += "    VisualHostKey yes\n"
                            host_line += "##########################\n"
                            host_line += "\n"
                            ssh_config_file.write(host_line)
                    except Exception as e:
                        raise e


        print("File updated: " + os.path.expanduser('~') + path_to_config)
        print(names)
    except Exception as e:
        print(e)

if __name__ == '__main__':
    main()
