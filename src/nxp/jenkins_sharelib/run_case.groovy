package nxp.jenkins_sharelib

def build_case(String k, String ll, String kk, Map item,
    String docker, String build_script, String pwd) {
    print('build ' + k)
    print(item['opt'][0])
    def _result = "BUILD_FAILURE"

    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
      for (cmd in item['scripts']) {
        def cmd_array = ['docker exec', docker, 'run_script.sh', pwd,
              item['opt'][1], cmd]
        sh cmd_array.join(" ")
      }
      if (item['opt'][2]) {
        def cmd_array = ['docker exec', docker, build_script, pwd, item['opt'][1],
              cmd, board, item['build']] + item['opt'][2..-1]
        sh cmd_array.join(' ')
      } else {
        def cmd_array = ['docker exec', docker, build_script, pwd, item['opt'][1],
          item['opt'][0], item['build']]
        sh cmd_array.join(' ')
      }
      _result = "SUCCESS"
    }

    return _result
}

def run_case(String k, String ll, String kk, Map item, String docker,
        String run_script, String pwd, String board, String version) {
    print('run ' + k)
    print(item['opt'][0])
    def _result = "FAILURE"

    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
        if (!item.has_key?('build_only')) {
          def cmd_array = ['docker exec', docker, run_script, pwd,
            item['build_path'], item['opt'][0], item['bin']]
            sh cmd_array.join(' ')
        }

        def build_path = "/build/src/workspace/" + pwd + "/zephyr/" + item['build_path']
        def cmd_array = ['docker exec', docker, 'rm -rf', build_path]
        sh cmd_array.join(' ')
        _result = "SUCCESS"
    }
    return _result
}

def report(String board, String k, String result, String version) {
    script {
      echo result
      myCustomMeasurementFields = ['results_info' : ['board_name': board, 'app_name': k,
        'result': result, 'version': version]]
      mycustomDataMapTags = ['results_info' :['board_name': board, 'app_name': k,
        'result': result, 'version': version]]
      influxDbPublisher(selectedTarget: 'influxdb', customDataMap: myCustomMeasurementFields, customDataMapTags: mycustomDataMapTags)
    }
}

return this