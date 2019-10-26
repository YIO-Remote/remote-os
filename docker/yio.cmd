@echo OFF
REM Wrapper build script for yio-remote/build Docker image
REM https://github.com/YIO-Remote/documentation/wiki

SET YIO_BUILD_OUTPUT=d:/projects/yio/build-output


IF NOT EXIST "%YIO_BUILD_OUTPUT%" (
    ECHO Output directory defined in 'YIO_BUILD_OUTPUT' doesn't exist: '%YIO_BUILD_OUTPUT%'
	EXIT /B 3
)

docker version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
	ECHO Docker is not running
	EXIT /B %ERRORLEVEL%
)

CALL :checkDockerVolume yio-projects2
IF %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%
CALL :checkDockerVolume yio-buildroot2
IF %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%

docker run --rm -it -v yio-projects:/yio-remote/src -v yio-buildroot:/yio-remote/buildroot -v "%YIO_BUILD_OUTPUT%":/yio-remote/target gcr.io/yio-remote/build %*
EXIT /B %ERRORLEVEL% 

:checkDockerVolume
docker volume inspect %~1 >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
	ECHO Docker volume '%~1' doesn't exist: creating it...
	docker volume create %~1
)

EXIT /B %ERRORLEVEL%