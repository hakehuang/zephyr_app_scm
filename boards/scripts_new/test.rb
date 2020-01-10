html_log = %q(
confirm job submission
test is in scheduling...  [Waiting]
test is queuing, waiting for running
test is running start
++++++++++++++++++++++++++
test execution finish
test result: Pass
<?xml version="1.0" ?>
<testsuites disabled="0" errors="0" failures="0" tests="1" time="1.0">
	<testsuite disabled="0" errors="0" failures="0" name="zephyr_test" skipped="0" tests="1" time="1">
		<testcase classname="hello_world" name="hello_world" time="1.000000"/>
	</testsuite>
</testsuites>

[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // parallel
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (failure)
[Pipeline] parallel
[Pipeline] { (Branch: sample.driver.gpio)
[Pipeline] stage
[Pipeline] { (sample.driver.gpio)
[Pipeline] echo
Test sample.driver.gpio
[Pipeline] echo
sample.driver.gpio
[Pipeline] catchError
[Pipeline] {
[Pipeline] sh
+ pwd
confirm job submission
test is in scheduling...  [Waiting]
test is running start
+++++++++++++++++++++
test execution finish
test result: Pass
<?xml version="1.0" ?>
<testsuites disabled="0" errors="0" failures="0" tests="1" time="1.0">
	<testsuite disabled="0" errors="0" failures="0" name="zephyr_test" skipped="0" tests="1" time="1">
		<testcase classname="sample.driver.gpio" name="sample.driver.gpio" time="1.000000"/>
	</testsuite>
</testsuites>

[Pipeline] }

)

puts "use default scan does not work for global search"

puts html_log.scan(/<testsuites(?:(?!<\/testsuites>).|\n)+<\/testsuites>/m).to_a


puts "=========================="

class String
	def scan(m)
		results = []
		logs = self.match(m).to_a
		istring = self.match(m).string
		while not logs.nil?
			istring = istring.sub(logs[0], '')
			results.insert(-1, logs[0])
			logs = istring.match(m)
		end
		return results
	end
end

puts "now it works"

puts html_log.scan(/<testsuites((?!<\/testsuites>).|\n)+<\/testsuites>/m)
