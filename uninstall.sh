if [ ! -e "/usr/local/bin/getloc" ]; then
  echo "getloc doesn't appear to be installed via this installer. Aborting."
  exit 1
fi

echo "This will uninstall getloc by removing /usr/local/bin/getloc and /usr/local/share/man/man1/getloc.1"
printf "Type 'yes' if you are sure you wish to continue: "
read response
if [ "$response" == "yes" ]; then
	sudo rm /usr/local/bin/getloc
	sudo rm /usr/local/share/man/man1/getloc.1
	sudo pkgutil --forget com.inspectorg.getloc.pkg
	echo "Uninstalled!"
else
	echo "Aborted."
	exit 1
fi

exit 0
