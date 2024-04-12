# @summary Class responsible for configurationk3s
class k3s::config (
  String $token_secret,
  String['init','joining'] $type,
) {
  # type as in the 'init'/first master or a 'joining' master
  case $type {
    'init': {
    }

    'joining': {
    }

    default: {
      fail('No valid configuration type provided.')
    }
  }
}
