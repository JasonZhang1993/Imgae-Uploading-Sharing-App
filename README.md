# Imgae-Uploading-Sharing-App
An ios app that inspired from the book **Cloud Computing for Machine Learning and Cognitive Application - Kai Hwang** Exercise 8.5, and We extended this practice to an application with completed functionality. 

The desciption of the exercise is as followed: 

> This problem asks you to practice mobile photo uploads to Amazon S3.
Explore some SDK tools on the AWS for using either iOS phone or any Android
phone to store photos on the Amazon S3 cloud and to notify AWS users using the
Simple Notification Service (SNS). Report on the storage/notification service
features, your testing results, and app experiences. Check the website for Android
SDK tools. Source Amazon: http://aws.amazon.com/sdkforandroid/. You can find
iOS and Android SDK tools by checking /sdk-for-ios/ and /sdk-for-android/,
similarly. Use the following three steps to do your experiments:
> 1. Download the Amazon AWS SDK for Android (or iOS) from the source URL.
> 2. Check the sample code given in aws-android-sdk-1.6/samples/S3_Uploader,
which creates a simple application that lets the user upload images from the
phone to an S3 bucket in a user account.
> 3. These images can be viewed by anyone with access to the URL shared by the
user.
> You need to perform the following operations and report the results in screen
snapshots or using any performance metric you choose to display when using an
Android phone. Similarly, for those students using Apple iOS phones, do the
following:
> 1. Try to upload the selected data (image) to the AWS S3 bucket, using the Access
key and Security Key credentials provided for the user. This will enable you as
an AWS client.
> 2. Check if the S3 bucket exists with the same name, and create the bucket and put
the image in S3 bucket.
> 3. Show in Browser button and display the image in the browser.
> 4. Make sure the image is treated as an image file in the web browser.
> 5. Create a URL for the image in the bucket, so that it can be shared and viewed by
other people.
> 6. Comment on extended applications beyond this experiment.

## Project Description

The Image Uploading and Sharing Application is an IOS application that provide interface for users to upload and share images to others. The functionality includes:
- Access to device photo albums and upload single of multiple images to the server (aws S3 of developers) that chosen by the user.
- Display the last uploaded image (single uplaod only) in the browser.
- Notified all users that subscribe by email when one uploaded new images through the app.
- All images are accessible to All users; they can preview through the app, or directly download to their photo albums.
- Subscribe or unsubscribe the email notification service.

## Infrastructure

Basically 3 interfaces that are independent and deveoped in parrallel through the app:

### 1. Uplaod
- UIImagePickerController to access to photo album and choose image to upload.
- upload action that uploads the image to S3 instace.
- When the upload process is done, a notification email will be sent to all subscribed users with a URL of the uploaded image. The notification service is deployed with aws SNS, and is executed in app backgroud.
- view action that take users to the browser to view the image.

### 2. download
- UITable displaying all image files on S3 with two actions:
  - view: preview the image in the app
  - download: downlaod the image data and save in the photo album

### 3. subscribe
- subscribe/unsubscribe the app through user's email address.
  
### 4. Multiple Upload
- choose at most 5 images from photo album, and upload them to S3.
  - Thanks for the work of @YangMingShan that provides the library of multiple images picker.
