Styling The App
###############

To ensure our app's layout and element positioning functions as expected, we now need to add some custom CSS.

In a Laravel application there are many ways to achieve this (e.g. webpack or NPM for larger projects).

The simplest way is to create the stylesheets (and Javascripts) directly in the **public/css** and **public/js** directories.

#. Make sure a file named **ntnx.css** exists in the **public/css** directory.  This file was created in an earlier section.

#. The contents of the **ntnx.css** file should be as follows:

    .. note::

       **Raw source file for this section, if required:** https://raw.githubusercontent.com/nutanixdev/lab-assets/master/php-lab-v3/ntnx.css

    .. code-block:: css

        @import url(https://fonts.googleapis.com/css?family=Open+Sans:300italic,700italic,700,300);
        @import url(https://fonts.googleapis.com/css?family=Droid+Sans);
        @import url(https://fonts.googleapis.com/css?family=Gafata);
        @import url(https://fonts.googleapis.com/css?family=Open+Sans:300);

        body {
            padding-bottom: 170px;
            font-family: "Open Sans";
        }

        .table {
            margin: 0 0 10px 0 !important;
        }

        .panel-heading {
            font-size: 24px;
        }

        .nav-pills > li.active > a,
        .nav-tabs > li.active a {
            color: #fff !important;
            background: #0D1F6F !important;
        }

        .tab-pane {
            padding: 13px !important;
        }

        .navbar-fixed-bottom a {
            color: #D9EBF9 !important;
        }

        .navbar {
            margin-bottom: 0;
            font-size: 125%;
        }

        .alert {
            text-align: center;
        }

        .info_big, .info_hilite, .info_error {
            font-size: 48px;
            vertical-align: middle;
            font-family: "Open Sans", Helvetica, Arial, sans-serif;
            color: #269347;
            text-align: center;
        }

        .info_hilite {
            color: #ffbc0d;
            font-size: 34px;
        }

        .info_error {
            color: #A00000;
            font-size: 34px;
        }

        .gridster ul li {
            border-radius: 4px;
            border: 1px solid #101010;
            background: #e8e8e8;
        }

        #footerWidget > .panel-body {
            padding: 10px 60px;
        }

Feel free to customise the appearance of the app later by modifying these CSS classes and properties.