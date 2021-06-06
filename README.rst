****************
Notejam: Express
****************

Notejam application deployed using NodeJS and Docker

========
Workflow
========

-------------
Updating code
-------------

.. code-block:: bash

    $ git add .
    $ git commit -m 'change'
    $ git push


-------
Cloning
-------

Clone the repo:

.. code-block:: bash

    $ git clone git@github.com:komarserjio/notejam.git YOUR_PROJECT_DIR/

-------------------
Install environment
-------------------
Use `npm <https://www.npmjs.org/>`_ to manage dependencies.

Install dependencies

.. code-block:: bash

    $ cd YOUR_PROJECT_DIR/express/notejam/
    $ npm install

Create database schema

.. code-block:: bash

    $ cd YOUR_PROJECT_DIR/express/notejam/
    $ node db.js

------
Launch
------

Start built-in web server:

.. code-block:: bash

    $ cd YOUR_PROJECT_DIR/express/notejam/
    $ DEBUG=* ./bin/www

Go to http://127.0.0.1:3000/ in your browser
