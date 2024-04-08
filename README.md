# OpenMRS Container

This is a build environment to build a docker image for OpenMRS based on official [Tomcat image](https://hub.docker.com/_/tomcat).

> [!TIP]
> If you like this project and find it useful, please consider starring :star: it on GitHub to help it reach more people and get more feedback.

The docker image is a self-contained Debian with OpenMRS, Tomcat and JDK installed, which will run on every distribution.

> [!NOTE]
> **Disclaimer**: The respective trademarks mentioned in the offering are owned by the respective companies. We do not provide a commercial license for any of these products. This listing has an open-source license. privacyIDEA is run and maintained by NetKnights, which is a complete and separate project from Khalibre.

## Get this image

The recommended way to get the OpenMRS Docker Image is to pull the prebuilt image from the Docker Hub Registry.

```bash
docker pull khalibre/openmrs-reference:latest
```

To use a specific version, you can pull a versioned tag. You can view the list of available versions in the Docker Hub Registry.

```bash
docker pull khalibre/openmrs-reference:[TAG]
```

If you wish, you can also build the image yourself by cloning the repository, changing to the directory containing the Dockerfile and executing the docker build command. Remember to replace the VERSION path placeholders in the example command below with the correct values.

```basg
git clone <https://github.com/khalibre/openmrs-docker.git>
cd VERSION
docker build -t khalibre/openmrs-reference:latest .
```

##Persisting your application

If you remove the container all your data and configurations will be lost, and the next time you run the image the database will be reinitialized. To avoid this loss of data, you should mount a volume that will persist even after the container is removed.

For persistence you should mount a directory at the `/opt/openmrs/data` path. If the mounted directory is empty, it will be initialized on the first run.

```bash
docker run -v /path/to/openmrs-persistence:/opt/openmrs/data khalibre/openmrs-reference:latest
```

Alternatively, modify the docker-compose.yml file present in this repository:

```yaml
services:
  openmrs:
  ...
    volumes:
      - /path/to/openmrs-persistence:/opt/openmrs/data
  ...
```

## Configuration

### Admin credentials

The OpenMRS container can create a default `admin` user and password. You can set the credentials with the following environment variable `OMRS_CONFIG_ADMIN_USER_PASSWORD` which is defaults to `Admin123`.

## Environment variables

### OpenMRS Environment Variables

Bellow are OpenMRS specific environment variables that can be used in the container.

| Environment Variable | Description | Default |
| :------------------- | :---------- | :------ |
| `OMRS_CONFIG_ADMIN_USER_PASSWORD` | Initial admin user password for OpenMRS login | `Admin123` |
| `OMRS_CONFIG_ADD_DEMO_DATA` | Automatically add demo data to OpenMRS database | `false` |
| `OMRS_CONFIG_AUTO_UPDATE_DATABASE` | Automatically update OpenMRS database | `true` |
| `OMRS_CONFIG_CONNECTION_NAME` | OpenMRS database name | `openmrs` |
| `OMRS_CONFIG_CONNECTION_PASSWORD` | OpenMRS database password | `openmrs` |
| `OMRS_CONFIG_CONNECTION_PORT` | OpenMRS database port | `3306` |
| `OMRS_CONFIG_CONNECTION_ROOT_PASSWORD` | OpenMRS database root password | `openmrs` |
| `OMRS_CONFIG_CONNECTION_ROOT_USERNAME` | OpenMRS database root username | `root` |
| `OMRS_CONFIG_CONNECTION_SERVER` | OpenMRS database server | `database` |
| `OMRS_CONFIG_CONNECTION_TYPE` | OpenMRS database type | `mysql` |
| `OMRS_CONFIG_CONNECTION_USERNAME` | OpenMRS database username | `openmrs` |
| `OMRS_CONFIG_CREATE_DATABASE_USER` | Create OpenMRS database user | `false` |
| `OMRS_CONFIG_CREATE_TABLES` | Create OpenMRS database tables | `false` |
| `OMRS_CONFIG_HAS_CURRENT_OPENMRS_DATABASE` | Check if OpenMRS database exists | `true` |
| `OMRS_CONFIG_INSTALL_METHOD` | OpenMRS installation method | `auto` |
| `OMRS_CONFIG_MODULE_WEB_ADMIN` | Enable web admin module | `true` |
| `OMRS_JAVA_MEMORY_OPTS` | Java memory options | `"-Xmx2048m -Xms1024m -XX:NewSize=128m"` |
| `OMRS_JAVA_SERVER_OPTS` | Java server options | `"-Dfile.encoding=UTF-8 -server -Djava.security.egd=file:/dev/./urandom -Djava.awt.headless=true -Djava.awt.headlesslib=true"` |

### Tomcat Environment Variables

Bellow are Tomcat specific environment variables that can be used in the container.

| Environment Variable | Description | Default |
| :------------------- | :---------- | :------ |
| `OMRS_TOMCAT_JPDA_ENABLED` | Enable JPDA | `false` |
| `JPDA_ADDRESS` | JPDA address | `0.0.0.0:8000` |
| `OMRS_TOMCAT_CONFIG_CORS_FILTER_ENABLED` | Enable CORS filter | `false` |
| `OMRS_TOMCAT_CONFIG_CORS_FILTER_ALLOWED_ORIGINS` | CORS filter allowed origins | `*` |

## Contributing

We'd love for you to contribute to this container. You can request new features by creating an issue, or submitting a pull request with your contribution.

You can also [file an issue](https://github.com/khalibre/openmrs-docker/issues) if you need help.
