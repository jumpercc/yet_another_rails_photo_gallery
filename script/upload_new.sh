#!/bin/bash

no_sign="false"
if [ "x$1" == "x--no-sign" ]
then
	no_sign="true"
fi

rails runner "require 'image_uploader'; ImageUploader.upload_images Rails.application.config.root.to_s, ${no_sign}"
