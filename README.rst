************
Notejam demo
************

The Notejam application is deployed using NodeJS and Docker


=================================
Environment deployment and update
=================================

After editing the Terraform configuration file, pushing it to the Terraform branch will
trigger the workflow. 

.. code-block:: bash

    $ git checkout terraform
    $ git add main.tf
    $ git commit -m 'change'
    $ git push

=================================
Application deployment and update
=================================

-------------
Updating code
-------------

.. code-block:: bash

    $ git checkout main
    $ git add .
    $ git commit -m 'change'
    $ git push

--------------
Build and push
--------------

"git push" triggers the workflow described by the main_notejam.yml file under .github/workflows

The workflow builds the container image based on the Dockerfile, pushes it to a private Azure Container Registry, and deployes it to App Service. 

----------
Deployment
----------

"docker push" triggers deployment/update of the application on Azure App Service.

The deployed application is available at http://notejam.azurewebsites.net
