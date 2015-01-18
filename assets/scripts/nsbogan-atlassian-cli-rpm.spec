%define __spec_install_post %{nil}
%define __os_install_post %{nil}
%define debug_package %{nil}
Summary: nsbogan-atlassian-cli
Name: nsbogan-atlassian-cli
Version: %{version}
Release: %{release}
License: Atlassian EULA Standard License
Vendor: Bob Swift Software, LLC
Packager: Maksym Grebenets <mgrebenets@gmail.com>
Group: Application/Development
Provides: %{name}
Requires: java
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}
Source: %{name}-%{version}.tar.gz
BuildArch: %{arch}

%description
Atlassian CLI tools by Bob Swift. See https://marketplace.atlassian.com/plugins/org.swift.atlassian.cli

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/nsbogan-atlassian-cli
tar -zxvf %{_sourcedir}/%{name}-%{version}.tar.gz -C %{buildroot}/opt/nsbogan-atlassian-cli
# cleanup windows bats
rm -f %{buildroot}/opt/nsbogan-atlassian-cli/*.bat
# patch shell scripts, rename and move to bin
mkdir -p %{buildroot}/opt/nsbogan-atlassian-cli/bin
# patch .sh files
for file in %{buildroot}/opt/nsbogan-atlassian-cli/*.sh; do
	# patch the path to lib before moving
	sed -i -e 's,/lib,/../lib,g' ${file}
	# inset JAVA_HOME export at 2nd line
	# use awk since couldn't figure out how to do it with sed '2i\ construction'
	awk 'NR==2 {print "[[ -d /usr/java ]] && export JAVA_HOME=/usr/java/$(ls -1 /usr/java | grep %{java_version} | tail -n1)"} {print}' ${file} > ${file}.bak && mv ${file}.bak ${file}
done

# customize atlassian.sh with products username, password and urls
filename=%{buildroot}/opt/nsbogan-atlassian-cli/atlassian.sh
sed -i.bak -e "s/\(.*user=\)'.*'/\1'%{username}'/g" $filename
sed -i.bak -e "s/\(.*password=\)'.*'/\1'%{password}'/g" $filename
# product urls
sed -i.bak -e "s,\(.*\)https://jira.example.com\(.*\),\1http://jira.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://bamboo.example.com\(.*\),\1http://bamboo.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://stash.example.com\(.*\),\1http://stash.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://confluence.example.com\(.*\),\1http://wiki.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://fisheye.example.com\(.*\),\1https://fisheye.nsbogan.com.au\2,g" $filename
sed -i.bak -e "s,\(.*\)https://crubicle.example.com\(.*\),\1https://crubicle.nsbogan.com.au\2,g" $filename

# all.sh - rename to atlassian-all.sh before moving
mv %{buildroot}/opt/nsbogan-atlassian-cli/all.sh %{buildroot}/opt/nsbogan-atlassian-cli/atlassian-all.sh

# move shell files
for file in %{buildroot}/opt/nsbogan-atlassian-cli/*.sh; do
	# move to bin with renaming
	BASE=$(basename ${file})
	NEW_NAME=${BASE%.sh}
	chmod +x ${file}
	# cat ${file} > $HOME/tmp/$(basename ${file}).txt

	# backwards compatibility (payback for bad decisions)
	cp ${file} %{buildroot}/opt/nsbogan-atlassian-cli/bin/atlas-${NEW_NAME}

	mv ${file} %{buildroot}/opt/nsbogan-atlassian-cli/bin/${NEW_NAME}
done

# cleanup backup files
rm -rf *.bak

%files
/opt/nsbogan-atlassian-cli

%post
# link binaries to /usr/local/bin
for file in /opt/nsbogan-atlassian-cli/bin/*; do
	ln -fs ${file} /usr/local/bin/$(basename ${file})
done

# link libraries to /usr/local/bin
for file in /opt/nsbogan-atlassian-cli/lib/*; do
	ln -fs ${file} /usr/local/lib/$(basename ${file})
done

%postun
# unlink binaries
for file in /opt/nsbogan-atlassian-cli/bin/*; do
	rm -f /usr/local/bin/$(basename ${file})
done

# unlink libs
for file in /opt/nsbogan-atlassian-cli/lib/*; do
	rm -f /usr/local/lib/$(basename ${file})
done

%clean
rm -rf %{buildroot}

%changelog
* Mon Jun 2 2014 - Maksym Grebenets <mgrebenets@gmail.com> %{version}-%{release}
- Upgrade to %{version}
