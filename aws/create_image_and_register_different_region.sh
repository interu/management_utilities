#!/bin/sh
#Usage: # sh create_image_and_register_different_region.sh
export RUBYLIB=$RUBYLIB:/usr/lib/ruby/site_ruby

export EC2_HOME=/usr/local/ec2/apitools
export JAVA_HOME=/usr/lib/jvm/jre

DATE=`date +"%Y%m%d_%H%M"`
AMI_DIR=/mnt/ami

PK_PEM_PATH=/root/.certs/pk-.pem
CERT_PEM_PATH=/root/.certs/cert-.pem

ACCESS_KEY=""
SECRET_KEY=""
ACCOUNT_ID=""
TARGET_REGION=""
TARGET_REGION_BUCKET=""
TARGET_REGION_KERNEL_ID=""
SHARING_USER_ID=""

echo "--------------------------"
echo "Remove old AMI images ..."
echo "--------------------------"

if [ -d "${AMI_DIR}" ]; then
  rm -rf ${AMI_DIR}
  rm -rf /mnt/img-mnt
fi

mkdir -p ${AMI_DIR}
cd ${AMI_DIR}

echo "--------------------------"
echo "Execute ec2-bundle-vol ..."
echo "--------------------------"
# Ref : http://dev.koba206.com/?p=61
/usr/local/bin/ec2-bundle-vol -d ${AMI_DIR} --privatekey ${PK_PEM_PATH} --cert ${CERT_PEM_PATH} --user ${ACCOUNT_ID} --kernel ${TARGET_REGION_KERNEL_ID}

echo "--------------------------"
echo "Execute ec2-upload-bundle ..."
echo "--------------------------"

ec2-upload-bundle --bucket ${TARGET_REGION_BUCKET}/${DATE} --manifest image.manifest.xml --access-key ${ACCESS_KEY} --secret-key ${SECRET_KEY}

echo "--------------------------"
echo "Regist AMI ..."
echo "--------------------------"

REGIST_RESULT=`/usr/local/ec2/apitools/bin/ec2-register --region ${TARGET_REGION} ${TARGET_REGION_BUCKET}/${DATE}/image.manifest.xml -K ${PK_PEM_PATH} -C ${CERT_PEM_PATH}`
echo ${REGIST_RESULT}

AMI_ID=`echo ${REGIST_RESULT} | grep "IMAGE" | awk '{print $2}'`
echo "AMI : ${AMI_ID}"

sleep 10

if echo ${AMI_ID} | grep "ami-"
then
  echo "--------------------------"
  echo "Change AMI permission ..."
  echo "--------------------------"
  /usr/local/ec2/apitools/bin/ec2-modify-image-attribute ${AMI_ID} -l -a ${SHARING_USER_ID} -K ${PK_PEM_PATH} -C ${CERT_PEM_PATH} --region ${TARGET_REGION}
else
  echo "[ERROR] AMI_ID is invalid."
fi
