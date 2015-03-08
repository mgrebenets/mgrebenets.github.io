//
// Jenkins Job DSL example to create build projects for Bitbucket branches
//

// Imports
import java.text.DateFormat
import java.text.SimpleDateFormat
import groovy.time.TimeCategory

// URL components
String baseUrl = "https://bitbucket.org/api"
String version = "1.0"
String organization = "i4niac"
String repository = "flappy-swift"

// put it all together
String branchesUrl = [baseUrl, version, "repositories", organization, repository, "branches"].join("/")

Boolean enableAuthentication = false

// create URL
URL url = branchesUrl.toURL()

// open connection
URLConnection connection = url.openConnection()

if (enableAuthentication) {
    String username = "i4niac"
    String password = "mypassword"

    // create authorization header using Base64 encoding
    String userpass = username + ":" + password;
    String basicAuth = "Basic " + javax.xml.bind.DatatypeConverter.printBase64Binary(userpass.getBytes());

    // set authorization header
    connection.setRequestProperty ("Authorization", basicAuth)
}

// open input stream
InputStream inputStream = connection.getInputStream()

// get JSON output
def branchesJson = new groovy.json.JsonSlurper().parseText(inputStream.text)

// close the stream
inputStream.close()

// Optional: set system proxy
Boolean setProxy = false
if (setProxy) {
    String host = "myproxyhost.com.au"
    String port = 8080

    System.getProperties().put("proxySet", "true");
    System.getProperties().put("proxyHost", host);
    System.getProperties().put("proxyPort", port);
}

// Note: no def or type used to declare this variables!
// list with names of major branches
majorBranches = ["master", "development", "release"]
// list with valid branch prefixes
validBranchPrefixes = ["feature", "bugfix", "hotfix"]
// all valid prefixes
allValidPrefixes = majorBranches + validBranchPrefixes

// check if the branch is a valid branch
Boolean isValidBranch(String name) {
    String prefix = name.split("/")[0]
    prefix in allValidPrefixes
}

// check if the branch is not too old
Boolean isUpToDateBranch(String branch, Date date) {
    // major branches are considered as always up to date
    if (branch in majorBranches) {
        true
    } else {
        def maxBranchAgeInDays = 15
        Date now = new Date()
        use (TimeCategory) {
            date.before(now) && date.after(now - maxBranchAgeInDays.days)
        }
    }
}

// iterate through branches JSON
branchesJson.each { branchName, details ->
    DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
    Date lastModified = dateFormat.parse(details["timestamp"])

    // check if branch name and age are valid
    if (isValidBranch(branchName) && isUpToDateBranch(branchName, lastModified)) {
        // branch is valid, create the job for it
        println "Valid branch: ${branchName}"

        // Configure the job
        job {
            name branchName.replaceAll('/','-')
            // TODO: the rest of Jenkins job configuration
        }
    }
}
