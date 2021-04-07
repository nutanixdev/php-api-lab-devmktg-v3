Accessing The Nutanix REST APIs
###############################

To summarise really quickly, we currently have a Laravel application setup as follows.

- Base Laravel 8 application
- **AjaxController** (empty for now) and **HomeController** classes in the `app/Http/Controllers` directory
- Customised routing to control which controller methods are used for each URL in the app
- Custom CSS stylesheets to control how our application looks
- Third-party libraries and packages to control additional appearance options and to provide additional JavaScript capabilities

That's all working properly, now.  The point of app, though, is to get information from a Nutanix Prism Central instance via REST API v3 and show that information inside our app.

Let's start doing that now.

The AjaxController class
........................

.. note::

   **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/AjaxController.php

So that the page isn't repeatedly reloaded every time we make a request, all Nutanix REST API requests will be completed via AJAX calls.  AJAX stands for Asynchronous JavaScript and XML and allows us to dynamically show information within the app without reloading the page.

Our **AjaxController.php** class is currently empty, but it is the core class used for all Asynchronous requests in our app.

For this reason, it does quite a few things.  Let's populate the contents of that class now.

#. Make sure a file named **AjaxController.php** exists in the **app/Http/Controllers** directory.  This file should exist as we created this class earlier.

#. The contents of the **AjaxController.php** file should be as follows:

    .. code-block:: php

        <?php

        namespace App\Http\Controllers;

        use Illuminate\Http\Request;
        use App\Models\ApiRequest;
        use App\Models\ApiRequestParameters;

        class AjaxController extends Controller
        {
            /**
            * Load the dashboard's layout
            *
            * @return \Illuminate\Http\JsonResponse
            */
            public function loadLayout()
            {
                $source_json = json_decode(file_get_contents(base_path() . '/config/dashboard.json', true));
                return response()->json(['layout' => base64_decode($source_json->layout)]);
            }

            /**
            * Internal method used to generate a base64-encoded Gridster layout
            */
            public function getEncodeLayout()
            {
                $layout = '[{"col":1,"row":1,"size_x":1,"size_y":1},{"col":1,"row":2,"size_x":1,"size_y":1},{"col":1,"row":3,"size_x":1,"size_y":1},{"col":2,"row":1,"size_x":2,"size_y":1},{"id":"bigGraph","col":2,"row":2,"size_x":2,"size_y":2},{"col":4,"row":1,"size_x":1,"size_y":1},{"col":4,"row":2,"size_x":2,"size_y":1},{"col":4,"row":3,"size_x":1,"size_y":1},{"col":5,"row":1,"size_x":1,"size_y":1},{"col":5,"row":3,"size_x":1,"size_y":1},{"col":6,"row":1,"size_x":1,"size_y":1},{"col":6,"row":2,"size_x":1,"size_y":2},{"id":"footerWidget","col":1,"row":4,"size_x":6,"size_y":1}]';
                echo base64_encode($layout);
            }

            /**
            * Save the current layout to the JSON configuration file
            *
            * @return \Illuminate\Http\JsonResponse
            */
            public function saveToJson()
            {
                $layout = base64_encode($_POST['_serialized']);
                $fullJson = json_encode(['version' => '1.0', 'layout' => $layout]);
                $file = base_path() . '/config/dashboard.json';
                file_put_contents($file, $fullJson);
                return response()->json(['result' => 0]);
            }

            /**
            * Return the dashboard to the default, before any changes are made
            *
            * @return \Illuminate\Http\JsonResponse
            */
            public function loadDefault()
            {
                $layout = file_get_contents(base_path() . '/resources/install/dashboard-default.json');
                return response()->json(['layout' => $layout]);
            }

            /**
            * Return a list of Prism Central managed entities, based on a specified entity identifier/name
            *
            * @return \Illuminate\Http\JsonResponse
            */
            public function pcListEntities()
            {

                $entity = $_POST['_entity'];

                $body = [ 'kind' => $entity ];

                $parameters = [
                    'username' => $_POST['_username'],
                    'password' => $_POST['_password'],
                    'cvmAddress' => $_POST['_cvmAddress'],
                    'objectPath' => $entity . 's/list',
                    'method' => 'POST',
                    'body' => json_encode($body),
                    'entity' => $entity
                ];

                $results = (new ApiRequest(new ApiRequestParameters($parameters)))->doApiRequest(null, 'POST');

                return response()->json(['results' => $results]);
            }

            /**
            *
            * Return some high level storage container performance stats
            *
            * @return \Illuminate\Http\JsonResponse
            */
            public function containerInfo()
            {

                /**
                * sample request shown below
                *
                * https://{cvm_ip}:9440/PrismGateway/services/rest/v1/containers/{container_uuid}/stats/?metrics={metric}&startTimeInUsecs={start_time}&endTimeInUsecs={end_time}&interval={interval_in_secs}
                *
                * Metric used below is controller_avg_io_latency_usecs
                *
                */

                $parameters = [
                    'username' => $_POST['_username'],
                    'password' => $_POST['_password'],
                    'cvmAddress' => $_POST['_cvmAddress'],
                    'objectPath' => 'clusters/list',
                    'method' => 'POST',
                    'body' => json_encode([
                        'kind' => 'cluster'
                    ]),
                    'entity' => 'cluster'
                ];

                $clusters = (new ApiRequest(new ApiRequestParameters($parameters)))->doApiRequest();

                /**
                * get the cluster virtual IP of the first cluster managed by this prism central instance
                * in production you wouldn't do this, but it is used here to illustrate the collection of container stats
                */

                $cluster_ip = $clusters->entities[0]->status->resources->network->external_ip;

                /**
                * now that we have the first cluster's virtual IP, we can connect to that cluster and get the first container's stats
                * note that we are explicitly telling this request to use api/nutanix/v2.0 as the top level request path, vs the api/nutanix/v3 default
                */

                $parameters = [
                    'username' => $_POST['_username'],
                    'password' => $_POST['_password'],
                    'cvmAddress' => $cluster_ip,
                    'objectPath' => 'storage_containers',
                    'method' => 'GET',
                    'topLevelPath' => 'api/nutanix/v2.0'
                ];

                $containers = (new ApiRequest(new ApiRequestParameters($parameters)))->doApiRequest();

                /**
                * based on the results of the container list request, we can now request stats for the first container in the list
                * it's possible these requests could be considered 'expensive' due to three requests being required for stats, but in a demo
                * app it will work ok
                */

                $firstContainerId = $containers->entities[0]->id;

                /**
                * build the parameters for our main request that will get the container's stats
                */
                
                $parameters = [
                    'username' => $_POST['_username'],
                    'password' => $_POST['_password'],
                    'cvmAddress' => $cluster_ip,
                    'objectPath' => 'containers',
                    'objectSubPath' => 'stats',
                    'objectId' => $firstContainerId,
                    'method' => 'GET',
                    'topLevelPath' => 'PrismGateway/services/rest/v1',
                    'startTime' => \Carbon\Carbon::now()->subHour(4),
                    'endTime' => \Carbon\Carbon::now(),
                    'interval' => 30,
                    'metric' => 'controller_avg_io_latency_usecs'
                ];

                $stats = (new ApiRequest(new ApiRequestParameters($parameters)))->doApiRequest();

                /**
                * at this point we have up to 4 hours worth of average latency stats for the first storage container in the first cluster managed
                * by our specified prism central instance
                * we now need to return those stats and then use javascript to generate a visual chart
                */

                /***********************************************/

                return response()->json(['stats' => [$stats->statsSpecificResponses[0]->values]]);
            }
        }

What does the **AjaxController** class do?

- Contains various methods to load the initial dashboard layout and revert the layout to a sensible default, if required.  These methods are **loadLayout()** and **loadDefault()**.
- Contains methods to save the user's layout, if they decide to keep their changes.  This method, **saveToJson()**, is called when the user clicks the **Save Layout** button in the application and instructs the app how to save the customised layout for later use.
- Contains the most important method: **pcListEntities()**.  This method is used in all our API requests and accepts a number of parameters to specify how the request should work.
- Lastly the method named **containerInfo()** talks to the first cluster found in Prism Central and gets some performance information about it.

Creating the JavaScript
.......................

With our classes created, the final (and probably most important) file can be created.

However, because this is such a key part of the application, it will be broken out into a separate (and final) part of this lab.

Click the button to continue!