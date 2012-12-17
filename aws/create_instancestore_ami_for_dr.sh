#!/bin/sh
# Usage: # sh create_instancestore_ami_for_dr.sh

if [[ -f ${HOME}/.ami_config.sh ]] ; then
  source ${HOME}/.ami_config.sh
else
  echo "Not exist config file."
  exit 0
fi

# Warn: please execute ruby 1.8.7.
confirm_execution() {
  echo  "You are using ruby `ruby -v`"
  echo "Using ruby 1.8.7 ? [yes/no]"
  read confirm
  if [ "$confirm" = "no" ]; then
    echo "Please execute following."
    echo ""
    echo "source /usr/local/rvm/scripts/rvm"
    echo "rvm use 1.8.7"
    echo ""
    exit 0
  elif [ "$confirm" = "yes" ]; then
    echo "Continue..."
  else
    confirm_execution
  fi
}
confirm_execution

export RUBYLIB=$RUBYLIB:/usr/lib/ruby/site_ruby
export EC2_HOME=/usr/local/ec2/apitools
export JAVA_HOME=/usr/lib/jvm/jre

DATE=`date +"%Y%m%d_%H%M"`
AMI_DIR=/mnt/ami

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
/usr/local/bin/ec2-bundle-vol -d ${AMI_DIR} --privatekey ${PK_PEM_PATH} --cert ${CERT_PEM_PATH} --user ${ACCOUNT_ID}

echo "--------------------------"
echo "Execute ec2-migrate-manifest ..."
echo "--------------------------"
ec2-migrate-manifest --privatekey ${PK_PEM_PATH} --cert ${CERT_PEM_PATH} --access-key ${ACCESS_KEY} --secret-key ${SECRET_KEY} --manifest image.manifest.xml --kernel ${DR_KERNEL_ID} --region ${DR_REGION}

echo "--------------------------"
echo "Execute ec2-upload-bundle ..."
echo "--------------------------"
ec2-upload-bundle --bucket ${DR_BUCKET}/${DATE} --manifest image.manifest.xml --access-key ${ACCESS_KEY} --secret-key ${SECRET_KEY} --location ${DR_REGION}
echo "y"

echo "--------------------------"
echo "Regist AMI ..."
echo "--------------------------"
REGIST_RESULT=`/usr/local/ec2/apitools/bin/ec2-register --region ${DR_REGION} ${DR_BUCKET}/${DATE}/image.manifest.xml -K ${PK_PEM_PATH} -C ${CERT_PEM_PATH}`
echo ${REGIST_RESULT}

AMI_ID=`echo ${REGIST_RESULT} | grep "IMAGE" | awk '{print $2}'`
echo "AMI : ${AMI_ID}"

sleep 5

if echo ${AMI_ID} | grep "ami-"
then
  echo "--------------------------"
  echo "Change AMI permission ..."
  echo "--------------------------"
  #/usr/local/ec2/apitools/bin/ec2-modify-image-attribute ${AMI_ID} -l -a ${SHARING_USER_ID} -K ${PK_PEM_PATH} -C ${CERT_PEM_PATH} --region ${DR_REGION}
else
  echo "[ERROR] AMI_ID is invalid."
fi

echo "if you are using rvm, please execute following command."
echo ""
echo "rvm use system"
