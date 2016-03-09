//
//  CameraViewController.swift
//  StoryLine
//
//  Created by Kareem Dasilva on 12/7/15.
//  Copyright © 2015 Apprentice Media LLC. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit


class CameraViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var camera: LLSimpleCamera!

    var mediaMode = "photo"
    struct StoryObject {
        var thumbnail = (UIImage)()
        var path:NSURL? = (NSURL)()
    }
    
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var previewHolder: UICollectionView!
    @IBOutlet weak var cameraView: UIView! //view for llcsimple camera
    @IBOutlet weak var shootBtn: UIButton!
    @IBOutlet weak var storyPreviewBar: UICollectionView! //Shows all media objects for the current story
    @IBOutlet weak var finishButton: UIBarButtonItem!
    @IBOutlet var flashBtn: UIButton!
    @IBOutlet weak var switchBtn: UIButton!
    @IBOutlet weak var modeSwitchControl: UISegmentedControl!
    @IBAction func switchMode(sender: AnyObject) {
        if mediaMode == "photo"{
            mediaMode = "video"
        } else {
            mediaMode = "photo"
        }
    }
    @IBAction func flashPressed(sender: AnyObject) {
        //turns on flash or off
        if camera.isFlashAvailable() == true {
            print("Flash is pressed")
            if self.camera.flash == CameraFlashOff {
                self.camera.updateFlashMode(CameraFlashOn)
                self.flashBtn.setTitle("Flash On", forState: UIControlState.Normal)
            } else {
                self.camera.updateFlashMode(CameraFlashOff)
                self.flashBtn.setTitle("Flash Off", forState: UIControlState.Normal)
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        
    }
    override func viewDidAppear(animated: Bool) {
        setupCamera()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitStory(sender: AnyObject) {
        print(self.mediaMode)
     
    }
    @IBAction func takeMediaShot(sender: AnyObject) {
        //function and button for taking media photos and movies
        let currentProgression = progressBar.progress
        if mediaMode == "photo"{
            if currentProgression > 0.9 {
                //no room for picture
                print("cannot take picture")
            } else {
                camera.capture({(camera: LLSimpleCamera!, image: UIImage!, metadata: [NSObject : AnyObject]!, error: NSError!) -> (Void) in
                    if (error == nil) {
                        print("Picture was tooken")
                        self.mediaObjects.append(StoryObject(thumbnail: image, path: nil))
                        camera.stop()
                        //let imageVC: imageViewController = imageViewController(image: image) //coder was "image"
                        // self.presentViewController(imageVC, animated: false, completion: nil)
                        self.progressBar.setProgress(self.progressBar.progress + 0.1, animated: true)
                        self.storyPreviewBar.reloadData()
                        camera.start()
                    }
                    else {
                        NSLog("An error has occured: %@", error)
                    }
                    
                    }, exactSeenImage: false)
                
            }
            
        } else if(self.mediaMode == "video") {
            
            let documents:NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let writePath = NSURL(fileURLWithPath: documents.stringByAppendingPathComponent("video.mov"), isDirectory: false)
            if camera.recording == false {
                camera.startRecordingWithOutputUrl(writePath)
                print("it recored")
                self.shootBtn.setTitle("Recoding", forState: UIControlState.Normal)
                self.shootBtn.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            } else {
                camera.stopRecording({(camera: LLSimpleCamera!, outputFileUrl: NSURL!, error: NSError!) -> (Void) in
                    print("it went well")
                    let asset = AVURLAsset(URL: outputFileUrl, options: nil)
                    let timeProgression:Float = Float(asset.duration.seconds/30.0)
                    if currentProgression + timeProgression > 1.0 {
                        // file is too long
                    } else {
                        // adds file to story
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        let cgImage =  try! imgGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil)
                        // !! check the error before proceeding
                        let uiImage = UIImage(CGImage: cgImage)
                        if error == nil {
                            self.mediaObjects.append(StoryObject(thumbnail: uiImage, path: outputFileUrl))
                            self.previewHolder.reloadData()
                            self.progressBar.setProgress(self.progressBar.progress + timeProgression, animated: true)
                            self.shootBtn.setTitle("Shoot", forState: UIControlState.Normal)
                            self.shootBtn.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
                            
                        } else {
                            print(error)
                        }
                    }
                })
            }
        } else {
            //preview mode
            let row = previewHolder.indexPathsForSelectedItems()?.last
            self.mediaObjects.removeAtIndex((row?.row)!)
            self.previewHolder.reloadData()
        }
    }
    
    @IBAction func switchCamera(sender: AnyObject) {
        self.camera.togglePosition()
    }
    
    func setupCamera(){
        //setups camera and adds other objects onto the current view
        self.camera = LLSimpleCamera(quality: AVCaptureSessionPresetHigh, position: CameraPositionBack, videoEnabled: true)
        camera.view.frame = cameraView.bounds
        self.cameraView.addSubview(camera.view)
        camera.start()
        self.mediaMode = "photo"
    }
    
    /*
    // MARK: - Image picker
    
    */
    let imagePicker = UIImagePickerController()
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func changeImage(sender: AnyObject) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        camera.stop()
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.mediaObjects.append(StoryObject(thumbnail: pickedImage, path: nil))
            self.progressBar.setProgress(self.progressBar.progress + 0.1, animated: true)
            self.storyPreviewBar.reloadData()
            camera.start()
        } else {
            print("it didnt work")
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /*
    // MARK: - Collection view
    This is where all the previews of phots/vedios are taken
    
    */
    //Holds all the previews
    var mediaObjects = [StoryObject]()
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let currentObject = mediaObjects[indexPath.row]
        //switch into preview mode
        self.mediaMode = "preview"
        self.cameraView.subviews.last?.removeFromSuperview()
        self.finishButton.title = "cancel"
        setupPreviewMode()
        if currentObject.path == nil {
            let previewView = UIImageView(frame: self.cameraView.bounds)
            previewView.image = currentObject.thumbnail
            previewView.contentMode = UIViewContentMode.ScaleAspectFit
            self.cameraView.addSubview(previewView)
        } else {
            let player = AVPlayer(URL: currentObject.path!)
            let playerView = AVPlayerViewController()
            playerView.player = player
            playerView.view.frame = self.cameraView.bounds
            self.cameraView.addSubview(playerView.view)
            playerView.player?.play()
            
        }
        
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = previewHolder.dequeueReusableCellWithReuseIdentifier("media", forIndexPath: indexPath) as! PreviewHolderCell
        cell.media.image = mediaObjects[indexPath.row].thumbnail
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return mediaObjects.count
    }
    func setupPreviewMode(){
        self.shootBtn.setTitle("Delete", forState: UIControlState.Normal)
        self.modeSwitchControl.hidden = true
    }
    
    
    @IBAction func finishPressed(sender: AnyObject) {
     
        if(self.mediaMode == "preview"){
            print("preview mode")
            let currentView = self.cameraView.subviews.last
            currentView?.removeFromSuperview()
            self.shootBtn.setTitle("Shoot", forState: UIControlState.Normal)
            self.finishButton.title = "Finish"
            self.modeSwitchControl.hidden = false
            setupCamera()
        }
        else
        {
            //lol
            /*var feedItems = [FeedItem]()
            var photos = [Photo]()
            var videos = [Video]()
            
            if let user = PFUser.currentUser() {
                
                for(var i=0; i < mediaObjects.count; i++){
                    
                    let photo = Photo()
                    let video = Video()
                    let feedItem = FeedItem()
                    
                    if((mediaObjects[i].path) != nil) //video
                    {
                        video.owner = user
                        video.url = mediaObjects[i].path
                        
                        /// Create the feed item object
                        feedItem.owner = user
                        feedItem.video = video
                        
                        print("saving video with owner: \(video.owner), url: \(video.url)")
                        
                        /// Start the video compression and uploading
                        video.upload({
                            (error) -> Void in
                            
                            if error != nil {
                                print(error)
                                return
                            }
                            
                            video.saveInBackground()
                            videos.append(video)
                            
                            },
                            progressBlock: {
                                (progress) -> Void in
                                
                                /// Optionally see the progress of the video upload
                        })
                    }
                        
                    else{ //photo
                        
                        photo.owner = user
                        
                        let imageData = UIImageJPEGRepresentation(mediaObjects[i].thumbnail, 0.1)
                        photo.image = PFFile(name: "storyImage", data: imageData!)!
                        
                        /// Create the feed item object
                        feedItem.owner = user
                        feedItem.photo = photo
                        
                        photo.saveInBackground()
                        photos.append(photo)
                    }
                    
                    //save remotely
                    feedItem.saveInBackground()
                    
                    //save locally, to add to story
                    feedItems.append(feedItem)
                }
                
                /// Create the story
                let story = Story()
                story.owner = user
                story.feedItems = feedItems
                story.initialize()
                
                
                delay(0.0) {
                    //PFObject.saveAllInBackground(photos, block: {  (succeeded: Bool, error: NSError?) -> Void in
                    // PFObject.saveAllInBackground(videos, block: {  (succeeded: Bool, error: NSError?) -> Void in
                    story.saveInBackgroundWithBlock({ (succeeded: Bool, error: NSError?) -> Void in
                        
                        for photo in photos{
                            photo["story"] = story
                            photo.saveInBackground()
                        }
                        
                        for video in videos{
                            video["story"] = story
                            video.saveInBackground()
                        }
                        
                        self.dismissViewControllerAnimated(false, completion: { () -> Void in
                            //should segue to newfeed here, but alert for now
                            let alert = UIAlertController(title: "Upload Complete!", message: "Message", preferredStyle: UIAlertControllerStyle.Alert)
                            self.presentViewController(alert, animated: true, completion: nil)
                        })
                    })//story save
                    //})//save videos
                    // })//save photos
                    
                }//delay
        }//if current user exists*/
        
        }
    }

    
//TEMP FUNC
    func delay(delay: Double, closure: ()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(),
            closure
        )
    }
}

class PreviewHolderCell: UICollectionViewCell {
    
    @IBOutlet weak var media: UIImageView!
    
}