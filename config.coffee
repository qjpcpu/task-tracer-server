config =
  me:
    host: 'http://localhost:8004'
  redis:
    host: "localhost"
    port: '6379'
    db: 7
  jwt:
    clientToken:
      secret: '9dd4cd'
      options:
        algorithm: 'HS256'
        expiresIn: '1 year' # expressed in seconds or an string describing a time span rauchg/ms. Eg: 60, "2 days", "10h", "7d"
    browserToken:
      secret: 'f6e'
      options:
        algorithm: 'HS256'
        expiresIn: '1 day' # expressed in seconds or an string describing a time span rauchg/ms. Eg: 60, "2 days", "10h", "7d"

module.exports = config
