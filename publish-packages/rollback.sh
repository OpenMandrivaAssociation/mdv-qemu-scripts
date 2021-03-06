#!/bin/sh

echo '--> mdv-scripts/publish-packages: rollback.sh'

released="$RELEASED"
rep_name="$REPOSITORY_NAME"
use_file_store="$USE_FILE_STORE"

echo "RELEASED = $released"
echo "REPOSITORY_NAME = $rep_name"

# Container path:
# - /home/vagrant/container
container_path=/home/vagrant/container

repository_path=/home/vagrant/share_folder
status='release'
if [ "$released" == 'true' ] ; then
  status='updates'
fi

# Update genhdlist2
sudo urpmi.update -a
sudo urpmi --auto genhdlist2

for arch in SRPMS i586 x86_64 ; do
  main_folder=$repository_path/$arch/$rep_name
  rpm_backup="$main_folder/$status-rpm-backup"
  m_info_backup="$main_folder/$status-media_info-backup"

  if [ -d "$rpm_backup" ] && [ "$(ls -A $rpm_backup)" ]; then
    mv $rpm_backup/* $main_folder/$status/
  fi

  if [ -d "$m_info_backup" ] && [ "$(ls -A $m_info_backup)" ]; then
    rm -rf $main_folder/$status/media_info
    cp -rf $m_info_backup $main_folder/$status/media_info
    rm -rf $m_info_backup
  fi

  # Remove new packages
  if [ "$use_file_store" != 'false' ]; then
    new_packages="$container_path/new.$arch.list"
    if [ -f "$new_packages" ]; then
      for sha1 in `cat $new_packages` ; do
        fullname=`sha1=$sha1 /bin/bash $script_path/extract_filename.sh`
        if [ "$fullname" != '' ] ; then
          rm -f $main_folder/$status/$fullname
        fi
      done
    fi
  else
    new_packages="$container_path/new.$arch.list.downloaded"
    if [ -f "$new_packages" ]; then
      for fullname in `cat $new_packages` ; do
        rm -f $main_folder/$status/$fullname
      done
      rm -rf $new_packages
    fi 
  fi

  rm -rf $rpm_backup $m_info_backup
done

exit 0