Classes
#######

For our application to function correctly we need to add a couple of PHP classes.  These classes will:

- Model the parameters used during an API call
- Carry out the actual API call itself.  In this application we are using the GuzzleHttp Composer package to do the heavy lifting, although production applications can opt to write ground-up request code, if required.

API parameter model
...................

.. note::

  **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/ApiRequestParameters.php

#. In the application's root directory, run the following command:

   ```
   php artisan make:model ApiRequestParameters
   ```

   This will create `ApiRequestParameters.php` in the `app/Models` directory.

#. The contents of **ApiRequestParameters.php** should be as follows:

    .. code-block:: php

        <?php

        namespace App\Models;

        use Illuminate\Database\Eloquent\Factories\HasFactory;
        use Illuminate\Database\Eloquent\Model;

        class ApiRequestParameters extends Model
        {
            use HasFactory;

            /**
            * The username to use during the connection
            */
            var $username;

            /**
            * The password to use during the connection
            */
            var $password;

            /**
            * The path for the top level API request
            */
            var $topLevelPath;

            /**
            * The IP address of the CVM
            */
            var $cvmAddress;

            /**
            * The port to connect on
            */
            var $cvmPort;

            /**
            * The timeout period i.e. how long to wait before the request is considered failed
            *
            * Note the connectTimeout value is used for connection, read and request timeout
            */
            var $connectionTimeout;

            /**
            * Is this a GET or POST request?
            */
            var $method;

            /**
            * The path to the main request e.g. containers, hosts
            */
            var $objectPath;

            /**
            * The ID of the object to make the request again
            */
            var $objectId;

            /**
            * The sub-path for the request, e.g. stats
            */
            var $objectSubPath;

            /**
            * The name of the metric to look at
            */
            var $metric;

            /**
            * The start time for the query
            */
            var $startTime;

            /**
            * The end time for the query
            */
            var $endTime;

            /**
            * The query interval e.g. 30 for every 30 seconds
            */
            var $interval;

            /**
            * The request body, if required
            */
            var $body;

            /**
            * The entity type to list, if that is the type of request being made
            */
            var $entity;

            /**
            * ApiRequestParameters constructor.
            * @param array $attributes
            */
            public function __construct(array $attributes)
            {
                $this->username = $attributes['username'];
                $this->password = $attributes['password'];
                $this->cvmAddress = $attributes['cvmAddress'];
                $this->cvmPort = isset($attributes['cvmPort']) ? $attributes['cvmPort'] : '9440';
                $this->topLevelStatsPath = isset($attributes['topLevelPath']) ? $attributes['topLevelPath'] : 'PrismGateway/services/rest/v1';
                $this->topLevelPath = isset($attributes['topLevelPath']) ? $attributes['topLevelPath'] : 'api/nutanix/v3';
                $this->connectionTimeout = isset($attributes['connectionTimeout']) ? $attributes['connectionTimeout'] : 5;
                $this->method = isset($attributes['method']) ? $attributes['method'] : 'GET';
                $this->objectPath = $attributes['objectPath'] != null ? $attributes['objectPath'] : null;
                $this->objectId = isset($attributes['objectId']) ? $attributes['objectId'] : null;
                $this->objectSubPath = isset($attributes['objectSubPath']) ? $attributes['objectSubPath'] : null;
                $this->metric = isset($attributes['metric']) ? $attributes['metric'] : null;
                $this->startTime = isset($attributes['startTime']) ? $attributes['startTime'] : null;
                $this->endTime = isset($attributes['endTime']) ? $attributes['endTime'] : null;
                $this->interval = isset($attributes['interval']) ? $attributes['interval'] : null;
                $this->body = isset($attributes['body']) ? $attributes['body'] : null;
                $this->entity = isset($attributes['entity']) ? $attributes['entity'] : null;
            }
        }

What does the **ApiRequestParameters** class do?

- Specifies a number of variables that can be passed to an API request e.g. the IP address of our cluster, username, password
- Specifies, importantly, the base URL for our API calls in this updated lab: **api/nutanix/v3**
- Checks to make sure all variables have been configured, otherwise some sensible defaults are set (null is the only option for some of them, as seen above)

API request class
.................

.. note::

  **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/ApiRequest.php

#. In the application's root directory, run the following command:

   ```
   php artisan make:model ApiRequest
   ```

   This will create `ApiRequest.php` in the `app/Models` directory.

#. The contents of **ApiRequest.php** should be as follows:

    .. code-block:: php

        <?php

        namespace App\Models;

        use Illuminate\Database\Eloquent\Factories\HasFactory;
        use Illuminate\Database\Eloquent\Model;

        class ApiRequest extends Model
        {
            use HasFactory;

            /**
            * The parameters to use while processing the request
            *
            * @var ApiRequestParameters
            */
            var $parameters;

            /**
            * ApiRequest constructor.
            *
            * @param ApiRequestParameters $parameters
            */
            public function __construct(ApiRequestParameters $parameters)
            {
                $this->parameters = $parameters;
                return $this;
            }

            /**
            * Process an API request
            * Supports both GET and POST requests
            *
            * @param $postParameters
            * @return mixed
            */
            public function doApiRequest($postParameters = null)
            {

                $path = '';
                switch ($this->parameters->method) {
                    case 'GET':

                        if (isset($this->parameters->objectId)) {
                            $path = sprintf(
                                "https://%s:%s/%s/%s/%s/%s?metrics=%s&startTimeInUsecs=%s&endTimeInUsecs=%s",
                                $this->parameters->cvmAddress,
                                $this->parameters->cvmPort,
                                $this->parameters->topLevelStatsPath,
                                $this->parameters->objectPath,
                                $this->parameters->objectId,
                                $this->parameters->objectSubPath,
                                $this->parameters->metric,
                                \Carbon\Carbon::parse($this->parameters->startTime)->timestamp * 1000000,
                                \Carbon\Carbon::parse($this->parameters->endTime)->timestamp * 1000000
                            );
                        } else {
                            $path = sprintf(
                                "https://%s:%s/%s/%s/",
                                $this->parameters->cvmAddress,
                                $this->parameters->cvmPort,
                                $this->parameters->topLevelPath,
                                $this->parameters->objectPath
                            );
                        }
                        break;
                    case 'POST':
                        $path = sprintf(
                            "https://%s:%s/%s/%s",
                            $this->parameters->cvmAddress,
                            $this->parameters->cvmPort,
                            $this->parameters->topLevelPath,
                            $this->parameters->objectPath
                        );
                        break;
                }

                $client = new \GuzzleHttp\Client();

                $response = $client->request(
                    $this->parameters->method,
                    $path,
                    [
                        'auth' => [ $this->parameters->username, $this->parameters->password ],
                        'verify' => false,
                        'connect_timeout' => $this->parameters->connectionTimeout,
                        'read_timeout' => $this->parameters->connectionTimeout,
                        'timeout' => $this->parameters->connectionTimeout,
                        'headers' => [
                            "Accept" => "application/json",
                            "Content-Type" => "application/json"
                        ],
                        'body' => $this->parameters->body
                    ]
                );

                /* return the response data in JSON format */
                return (json_decode($response->getBody()));
            }
        }

What does the **ApiRequest** class do?

- Takes an array of parameters.  This is an **instance** of the **ApiRequestParameters** class
- Sets up the configuration of the API request
- Carries out the actual request and returns the results in JSON format

.. raw:: html

  <p><strong><font color="red">Important note: The classes used in this app intentionally bypass the verification of SSL certificates used during the CVM/cluster connection.  It is strongly advised that appropriate security practices are followed in production environments and that all certificates are verified as connections are made.</font></strong></p>

Making classes usable
.....................

A couple of quick commands need to be run before the classes are usable.

#. Run these commands in the app's root directory.

   .. code-block:: bash

      php artisan clear-compiled
      composer -o dump-autoload
