Creating the app structure
##########################

With our system now correctly configured to run Laravel PHP applications, we can start creating the application itself.

The key components of our app are as follows.

- Our Laravel base application, created in the previous step
- A Nutanix cluster, running Acropolis 5.18 or later
- An instance of Prism Central version 5.18 or later, with your lab cluster registered against that instance
- The Nutanix REST APIs. Note that this application reads Prism Central information.  This dictates that we will be using API v3.
- A collection of third-party Javascripts and CSS that simplify front-end operations.  For those already familiar, this is primarily done using `jQuery <https://jquery.com>`_.
- An application-specific "master" Javascript that handles the communications between the front-end and the Nutanix REST APIs.

Adding required packages
........................

#. If your Laravel application is still running, press Ctrl-C to terminate the built-in PHP web server.

#. From the command line, run the following commands.  This will add 3 required packages to our application's **composer.json** file.

   .. code-block:: bash

      composer require laracasts/flash

   The screenshot below shows the output from the Laracasts Flash command above:

   .. figure:: images/composer_install_flash.png

Configuring new packages
........................

.. note::

   All directories and paths referenced from this point in the lab will be located in **api-app-lab-v3-<your_initials>** directory you created in the previous step.

With the new packages added, we need to tell Laravel how to use them.

#. In your code editor, open the **config/app.php** file and navigate to the **providers** section.

#. Add the following lines just before the end of the **providers** section.

   **You may need to add a comma after the end of current last line.**

   .. code-block:: php

      Laracasts\Flash\FlashServiceProvider::class,

   After adding the providers, end of your 'providers' section should look as follows:

   .. figure:: images/add_providers.png

#. Navigate to the **aliases** section.

#. Add the following lines just before the end of the **aliases** section.

   **You may need to add a comma after the end of the current last line.**

   .. code-block:: php

      'Flash' => Laracasts\Flash\Flash::class,

   After adding the aliases, end of your 'aliases' section should look as follows:

   .. figure:: images/add_aliases.png

Publish the 'Flash' package files
.................................

#. Publish the vendor package files by moving views, controllers (etc) into the correct application locations.  The 'Flash' package, used to show pretty messages, requires that its files are moved to specific locations within the app.

   .. code-block:: bash

      php artisan vendor:publish

#. When prompted, select the option shown next to **Provider: Laracasts\Flash\FlashServiceProvider** and press enter.

   .. figure:: images/publish_vendor.png

Creating the app controllers
............................

Our app contains two main controllers; **HomeController** and **AjaxController**.  For now, we can create shell controllers that don't do anything (yet).

#. To create our temporarily empty controllers, run the following commands from the app's directory.

   .. code-block:: bash

      php artisan make:controller HomeController
      php artisan make:controller AjaxController

#. Since this is the first time we've used artisan's **make** feature, check for the existence of files named **AjaxController** and **HomeController** in the **app/Http/Controllers** directory.

Disabling CSRF Protection
.........................

.. note::

  **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/VerifyCsrfToken.php

**Don't do this in production!**

For our app, we don't need CSRF protection for our routes.  CSRF protection is Laravel's built-in way of making sure a POST request is what it says it is by sending a CSRF token with that request.  If the token doesn't match, the POST request is rejected.

#. Open the **app/Http/Middleware/VerifyCsrfToken.php** file

#. The default configuration looks like this:

   .. code-block:: php

      protected $except = [
        //
      ];

#. Change the configuration to this so that CSRF protection is disabled specifically for POST requests to our AJAX methods:

   .. code-block:: php

      protected $except = [
        'ajax/load-layout',
        'ajax/pc-list-entities',
        'ajax/container-info',
        'ajax/save-to-json',
        'ajax/load-default'
      ];

The first controller method
...........................

.. note::

  **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/HomeController.php

#. Open the **app/Http/Controllers/HomeController.php** file.  It's empty right now, with a single-line comment block (**//**).

#. Replace the single-line comment block with the following method.

    .. code-block:: php

       /**
       * Load the main view
       *
       * @return mixed
       */
       public function index()
       {

           $layout = '[{"col":1,"row":1,"size_x":1,"size_y":1},{"col":1,"row":2,"size_x":1,"size_y":1},{"col":1,"row":3,"size_x":1,"size_y":1},{"col":2,"row":1,"size_x":2,"size_y":1},{"col":2,"row":2,"size_x":2,"size_y":2},{"col":4,"row":1,"size_x":1,"size_y":1},{"col":4,"row":2,"size_x":2,"size_y":1},{"col":4,"row":3,"size_x":1,"size_y":1},{"col":5,"row":1,"size_x":1,"size_y":1},{"col":5,"row":3,"size_x":1,"size_y":1},{"col":6,"row":1,"size_x":1,"size_y":1},{"col":6,"row":2,"size_x":1,"size_y":2}]';

           $source_json = json_decode( file_get_contents( base_path() . '/config/dashboard.json', true ) );

           if( $source_json->version ) {
               $layout = base64_decode( $source_json->layout );
           }
           else {
               $layout = null;
           }

           return view( 'home.index' )->with( 'data', [ 'layout' => $layout ] );

       }
       /* index */

  The **index** method is the function that will be called when someone browses to the app's root URL (**/**).  At a high level, it does the following things:

  - Sets up a default grid layout.  This layout is based on the jQuery **Gridster** plugin.
  - Loads a default layout from a file provided with the app - we will create that file shortly.
  - Using the layout information that has been created, it returns an HTML view to the user.

.. note::

   The layout information in **dashboard.json** (created shortly) is stored after being base64-encoded.  The **base64_decode** function decodes this data and returns it in plain-text JSON format.

Default layouts
...............

.. note::

  **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/dashboard.json

As mentioned above, a default layout is loaded when the user browses to **/**.  Let's now create that default layout.

#. Inside the **config** directory, create a file named **dashboard.json**.  This file describes the application layout that will be loaded at first run.  The contents of the file should be as follows:

   .. code-block:: json

      {"version":"1.0","layout":"WwogIHsKICAgICJpZCI6ICJyZWdpc3RlcmVkX2NsdXN0ZXJzIiwKICAgICJjb2wiOiAxLAogICAgInJvdyI6IDEsCiAgICAic2l6ZV94IjogMiwKICAgICJzaXplX3kiOiAxCiAgfSwKICB7CiAgICAiaWQiOiAiaW1hZ2VfY291bnQiLAogICAgImNvbCI6IDMsCiAgICAicm93IjogMSwKICAgICJzaXplX3giOiAyLAogICAgInNpemVfeSI6IDEKICB9LAogIHsKICAgICJpZCI6ICJ2bV9jb3VudCIsCiAgICAiY29sIjogNSwKICAgICJyb3ciOiAxLAogICAgInNpemVfeCI6IDIsCiAgICAic2l6ZV95IjogMQogIH0sCiAgewogICAgImlkIjogImhvc3RfY291bnQiLAogICAgImNvbCI6IDEsCiAgICAicm93IjogMiwKICAgICJzaXplX3giOiAxLAogICAgInNpemVfeSI6IDEKICB9LAogIHsKICAgICJpZCI6ICJiaWdHcmFwaCIsCiAgICAiY29sIjogMiwKICAgICJyb3ciOiAyLAogICAgInNpemVfeCI6IDIsCiAgICAic2l6ZV95IjogMgogIH0sCiAgewogICAgImlkIjogInByb2plY3RfY291bnQiLAogICAgImNvbCI6IDQsCiAgICAicm93IjogMiwKICAgICJzaXplX3giOiAyLAogICAgInNpemVfeSI6IDEKICB9LAogIHsKICAgICJpZCI6ICJwcm9qZWN0X2RldGFpbHMiLAogICAgImNvbCI6IDYsCiAgICAicm93IjogMiwKICAgICJzaXplX3giOiAxLAogICAgInNpemVfeSI6IDIKICB9LAogIHsKICAgICJpZCI6ICJhcHBfY291bnQiLAogICAgImNvbCI6IDEsCiAgICAicm93IjogMywKICAgICJzaXplX3giOiAxLAogICAgInNpemVfeSI6IDEKICB9LAogIHsKICAgICJpZCI6ICJoaW50cyIsCiAgICAiY29sIjogNCwKICAgICJyb3ciOiAzLAogICAgInNpemVfeCI6IDIsCiAgICAic2l6ZV95IjogMQogIH0sCiAgewogICAgImlkIjogImZvb3RlcldpZGdldCIsCiAgICAiY29sIjogMSwKICAgICJyb3ciOiA0LAogICAgInNpemVfeCI6IDYsCiAgICAic2l6ZV95IjogMQogIH0KXQ=="}

#. Inside the **resources** directory, create a subdirectory named **install**.

#. Inside the new **install** directory, create a file named **dashboard-default.json**.  This file describes the application layout when it is **reverted to default**.  The contents of the file should be as follows.

   .. note::

      **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/dashboard-default.json

   .. code-block:: json

      [
        {
            "id": "registered_clusters",
            "col": 1,
            "row": 1,
            "size_x": 2,
            "size_y": 1
        },
        {
            "id": "image_count",
            "col": 3,
            "row": 1,
            "size_x": 2,
            "size_y": 1
        },
        {
            "id": "vm_count",
            "col": 5,
            "row": 1,
            "size_x": 2,
            "size_y": 1
        },
        {
            "id": "host_count",
            "col": 1,
            "row": 2,
            "size_x": 1,
            "size_y": 1
        },
        {
            "id": "bigGraph",
            "col": 2,
            "row": 2,
            "size_x": 2,
            "size_y": 2
        },
        {
            "id": "project_count",
            "col": 4,
            "row": 2,
            "size_x": 2,
            "size_y": 1
        },
        {
            "id": "project_details",
            "col": 6,
            "row": 2,
            "size_x": 1,
            "size_y": 2
        },
        {
            "id": "app_count",
            "col": 1,
            "row": 3,
            "size_x": 1,
            "size_y": 1
        },
        {
            "id": "hints",
            "col": 4,
            "row": 3,
            "size_x": 2,
            "size_y": 1
        },
        {
            "id": "footerWidget",
            "col": 1,
            "row": 4,
            "size_x": 6,
            "size_y": 1
        }
      ]

   The JSON in these files will be used and explained in more detail in a later step.

The main view
.............

.. note::

  **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/index.blade.php

Because Laravel apps are based on the MVC (Model, View, Controller) design pattern, the next thing to do is create the main view for our app.  A simple 'Welcome' view is provided with Laravel (we saw it when making sure the app works), but we are going to create one more.

**Note**: Unless mentioned otherwise, all directory paths in this lab will be based on the root of your app.

#. Inside the **resources/views** directory, create a subdirectory named **home**

#. Inside the new **home** directory, create a file named **index.blade.php**.  For now, the contents of **index.blade.php** should be as follows.  These contents setup the base HTML5 page, a navigation bar and include directives for our scripts and stylesheets.

    .. code-block:: html

        <!doctype html>
        <html lang="en">

        <head>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Nutanix Dashboard</title>
            <link rel="stylesheet" type="text/css" href="/css/vendor/reset.css" />
            <link rel="stylesheet" type="text/css" href="/css/vendor/built-in.css" />
            <link rel="stylesheet" type="text/css" href="/css/vendor/jquery-ui.min.css" />
            <link rel="stylesheet" type="text/css" href="/css/vendor/jq.dropdown.min.css" />
            <link rel="stylesheet" type="text/css" href="/css/vendor/jq.gridster.css" />
            <link rel="stylesheet" type="text/css" href="/css/vendor/jq.jqplot.css" />
            <link rel="stylesheet" type="text/css" href="/css/ntnx.css" />
        </head>

        <body>

            <nav class="navbar navbar-default navbar-fixed-top main-nav">
                <div class="container-fluid">
                    <div class="collapse navbar-collapse">

                        <ul class="nav navbar-nav">

                            <li><a href="#">Home</a></li>
                            <li><a href="#" class="saveLayout">Save Layout</a></li>
                            <li><a href="#" class="defaultLayout">Revert to Default Layout</a></li>

                        </ul>

                        <form action="/" method="POST" class="navbar-form navbar-form-left">
                        @csrf
                        <div class="form-group">
                            <input type="text" name="cvmAddress" id="cvmAddress" value="" class="form-control" placeholder="Prism Central IP">
                            <input type="text" name="username" id="username" value="" class="form-control" placeholder="Prism Central Username">
                            <input type="password" name="password" id="password" value="" class="form-control" placeholder="Prism Central Password">
                            <input type="submit" name="goButton" id="goButton" value="Go!" class="btn btn-primary">
                        </div>
                        </form>

                    </div>
                </div>
            </nav>

            <div class="container" style="margin-top: 20px;">
                <div class="row">
                    <div class="col-md-15">
                        @include( 'vendor.flash.message' )
                        <div class="container">
                            <div class="row">
                                <div class="col-md-15">

                                    <div class="gridster">
                                        <ul>
                                            {{-- The grid layout will end up here, once it is generated --}}
                                        </ul>
                                    </div>

                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div style="height: 70px; clear: both;">&nbsp;</div>

            <script src="/js/vendor/jquery-3.4.1.min.js"></script>
            <script src="/js/vendor/jq.dropdown.min.js"></script>
            <script src="/js/vendor/classie.min.js"></script>
            <script src="/js/vendor/ntnx-bootstrap.min.js"></script>
            <script src="/js/vendor/modernizr-custom.js"></script>
            <script src="/js/vendor/jquery.jqplot.min.js"></script>
            <script src="/js/vendor/jqplot.logAxisRenderer.js"></script>
            <script src="/js/vendor/jqplot.categoryAxisRenderer.js"></script>
            <script src="/js/vendor/jqplot.canvasAxisLabelRenderer.js"></script>
            <script src="/js/vendor/jqplot.canvasTextRenderer.js"></script>
            <script src="/js/vendor/jqplot.barRenderer.js"></script>
            <script src="/js/vendor/jquery.gridster.min.js"></script>
            <script src="/js/ntnx.js"></script>

        </body>

        </html>

Connecting the main view
........................

.. note::

  **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/web.php

Right now, we can't access the new home page - we need to tell Laravel how to display that page, based on the URL provided by the user.

#. Open the **routes/web.php** file and ensure the contents are as follows:

   .. code-block:: php

      <?php

      use Illuminate\Support\Facades\Route;
      use App\Http\Controllers\HomeController;
      use App\Http\Controllers\AjaxController;

      /*
      |--------------------------------------------------------------------------
      | Web Routes
      |--------------------------------------------------------------------------
      |
      | Here is where you can register web routes for your application. These
      | routes are loaded by the RouteServiceProvider within a group which
      | contains the "web" middleware group. Now create something great!
      |
      */

      // main app route that loads the home page each time a new session is started
      Route::get('/', [HomeController::class, 'index']);

      // routes used by various form & method callbacks
      Route::post( 'ajax/load-layout', [AjaxController::class, 'loadLayout']);
      Route::post( 'ajax/load-default', [AjaxController::class, 'loadDefault']);
      Route::post( 'ajax/save-to-json', [AjaxController::class, 'saveToJson']);
      Route::post( 'ajax/container-info', [AjaxController::class, 'containerInfo']);
      Route::post( 'ajax/pc-list-entities', [AjaxController::class, 'pcListEntities']);

   The first line instructs Laravel serve all requests to **/** (the app's root directory) by running the **index** method from the **HomeController** controller.

   The remaining lines specify which AjaxController methods to use for each of the URLs used by our app.  We'll create those shortly.
   
   **Route::get** specifies that a route can only be accessed via an HTTP GET request, whereas **Route::post** specifies that a route can only be accessed via an HTTP POST request.

Initial app testing
...................

At this point, your application doesn't do anything useful.  However, the basic structure has been completed and we're ready to start wiring the important parts together.

#. If your application is not currently running, start the development server now:

   .. code-block:: bash

      php artisan serve

#. Browse to the root of your application and make sure you can see a form prompting for the following items:

   1. Cluster/CVM IP
   2. Cluster username
   3. Cluster password

   There should also be three links at the top of the screen - **Home**, **Save Layout** and **Revert to Default Layout**.

   .. figure:: images/unstyled.png

   If you are wondering why our app looks fairly unattractive right now, it's because we haven't added any styling or formatting, yet.  We'll do that in an upcoming step, though.