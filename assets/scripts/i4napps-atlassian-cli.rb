require 'formula'

# Homebrew formula to install atlassian CLI tools
class I4nAppsAtlassianCli < Formula    
    version "3.9.0"
    def release() "1" end   # custom release field
    def java_version() ENV["JAVA_VERSION"] || "1.6" end    # java version to set JAVA_HOME

    homepage 'https://marketplace.atlassian.com/plugins/org.swift.atlassian.cli'
    url "https://marketplace.atlassian.com/download/plugins/org.swift.atlassian.cli/version/#{version.to_s.delete('.')}"
    sha1 'c18174f5dee921f69fedd663bd4a9e330565a7d3'

    # nested i4nApps environment class
    class I4nAppsEnv
        # Patch the shell script above
        # @param [String] filename name of shell script to patch
        def patch(filename)
            # username and password
            %x[ sed -i -e \"s/\\(.*user=\\)'.*'/\\1'#{username}'/g\" #{filename} ]
            %x[ sed -i -e \"s/\\(.*password=\\)'.*'/\\1'#{password}'/g\" #{filename} ]
            # server urls for products, use internal knowledge that atlassian.sh has links like https://<product>.example.com
            products.each do |product|
                %x[ sed -i -e \"s,\\(.*\\)https://#{product.to_s}.example.com\\(.*\\),\\1#{server(product)}\\2,g\" #{filename} ]
            end
        end

        # Get list of products for enumeration
        # @return [Array<Symbol>] array of product types
        def products
            [ :jira, :bamboo, :stash, :confluence, :fisheye, :crucible ]
        end

        # Atlassian Product servers
        @@servers = {
            :jira => "http://jira.i4napps.com.au",
            :bamboo => "http://bamboo.i4napps.com.au",
            :stash => "http://stash.i4napps.com.au",
            :confluence => "http://wiki.i4napps.com.au",
            :fisheye => "http://fisheye.i4napps.com.au",
            :crucible => "https://crucible.i4napps.com",
        }

        # Get server url for product
        # @param [Symbol] product +:jira+, +:bamboo+, +:stash+, +:confluence+, +:fisheye+, +:crucible+
        # @return [String] server url
        def server(product)
            @@servers[product.to_sym]
        end

        # Username for Atlassian servers
        # @note Optionally use ATLASSAIN_USERNAME environment variable when installing
        # @return [String] username
        def username
            ENV["ATLAS_USERNAME"]
        end

        # Username for Atlassian servers
        # @note Optionally use ATLASSAIN_PASSWORD environment variable when installing
        # @return [String] password
        def password
            ENV["ATLAS_PASSWORD"]
        end
    end

    # dependencies (if any)

    # Install
    def install

        # this is garbage
        puts "Cleaning up windows stuff..."
        rm Dir["*.bat"]

        # TODO: consider removing examples and all the other stuff

        # patch before moving to bin
        puts "Patching shell scripts and moving them to bin..."
        Dir['*.sh'].each do |f|
            # patch by updating path to lib folder
            %x[ sed -i -e 's,/lib,/../lib,g' #{f} ]
            # patch by inserting and setting JAVA_HOME
            %x[ awk 'NR==2 {print "export JAVA_HOME=$(/usr/libexec/java_home -v #{java_version})"} {print}' #{f} > #{f}.bak && mv #{f}.bak #{f} ]
        end

        # customize bin/atlassian (renamed from atlassian.sh) with username, password and server urls
        # !!!: must patch before install command
        puts "Customizing product endpoints, username and password...."
        I4nAppsEnv.new.patch("atlassian.sh")

        # move all shell executables to bin, that's the way homebrew understands it
        # also drop the .sh part
        Dir.mkdir "bin"
        Dir['*.sh'].each { |f| mv f, "bin/#{f.gsub('.sh', '')}" }
        # all.sh, really? how about atlassian-all?
        mv "bin/all", "bin/atlassian-all"

        prefix.install_metafiles
        prefix.install Dir['*']
    end

    test do
        puts "version: #{version}-#{release}"
        %x[ jira ]
    end
end
