#!/bin/bash
# example:
# bash network_usage.sh  ap-south-1  NetworkOut  2020-06-01T00:00:00.000Z  2020-06-30T23:59:59.000Z

if [ $# -ne 4 ]; then
	echo "Usage: $0 <REGION> <NetworkIn|NetworkOut> <START_TIMESTAMP> <END_TIMESTAMP>"
	echo -e "\tNote: Do not change the order of parameters."
	echo -e "\n\tExample: $0 ap-south-1 NetworkOut 2020-06-01T00:00:00.000Z 2020-06-30T23:59:59.000Z"
	exit 1
fi

REGION="$1"
METRIC="$2"
START_TIME="$3"
END_TIME="$4"

ADD_INSTANCES=""

INSTANCES="${ADD_INSTANCES} $(aws ec2 describe-instances --region ${REGION} --query Reservations[*].Instances[*].InstanceId --output text)" || { echo "Failed to run aws ec2 describe-instances commandline, exiting..."; exit 1; }

[ "${INSTANCES}x" == "x" ] && { echo "There are no instances found from the given region ${REGION}, exiting..."; exit 1; }

for _instance_id in ${INSTANCES}; do
	unset _value
	_value="$(aws cloudwatch get-metric-statistics --metric-name ${METRIC} --start-time ${START_TIME} --end-time ${END_TIME} --period 86400 --namespace AWS/EC2 --statistics Sum --dimensions Name=InstanceId,Value=${_instance_id} --region ${REGION} --output text)"
	[ "${_value}x" == "x" ] && { echo "Something went wrong while calculating the network usage of ${_instance_id}"; continue; }
	echo "${_instance_id}: $(echo "${_value}" | awk '{ sum += $2 } END {printf ("%f\n", sum/1024/1024/1024)}';) GiB";
done

echo -e "\nNote: If you think the values are inaccurate, please verify the input and modify if needed."
