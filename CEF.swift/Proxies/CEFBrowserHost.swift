//
//  CEFBrowserHost.swift
//  CEF.swift
//
//  Created by Tamas Lustyik on 2015. 07. 25..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

import Foundation


public extension CEFBrowserHost {

    /// Create a new browser window using the window parameters specified by
    /// |windowInfo|. All values will be copied internally and the actual window
    /// will be created on the UI thread. If |request_context| is empty the
    /// global request context will be used. This method can be called on any
    /// browser process thread and will not block.
    public static func createBrowser(windowInfo: CEFWindowInfo,
                                     client: CEFClient? = nil,
                                     url: NSURL? = nil,
                                     settings: CEFBrowserSettings,
                                     requestContext: CEFRequestContext? = nil) -> Bool {
        var cefSettings = settings.toCEF()
        let cefURLPtr = url != nil ? CEFStringPtrCreateFromSwiftString(url!.absoluteString) : nil
        var cefWinInfo = windowInfo.toCEF()
        let cefClient = client != nil ? client!.toCEF() : nil
        let cefReqCtx = requestContext != nil ? requestContext!.toCEF() : nil
        
        defer {
            cefSettings.clear()
            CEFStringPtrRelease(cefURLPtr)
            cefWinInfo.clear()
        }
        
        return cef_browser_host_create_browser(&cefWinInfo, cefClient, cefURLPtr, &cefSettings, cefReqCtx) != 0
    }

    /// Create a new browser window using the window parameters specified by
    /// |windowInfo|. If |request_context| is empty the global request context
    /// will be used. This method can only be called on the browser process UI
    /// thread.
    public static func createBrowserSync(windowInfo: CEFWindowInfo,
                                         client: CEFClient? = nil,
                                         url: NSURL? = nil,
                                         settings: CEFBrowserSettings,
                                         requestContext: CEFRequestContext? = nil) -> CEFBrowser? {
        var cefSettings = settings.toCEF()
        let cefURLPtr = url != nil ? CEFStringPtrCreateFromSwiftString(url!.absoluteString) : nil
        var cefWinInfo = windowInfo.toCEF()
        let cefClient = client != nil ? client!.toCEF() : nil
        let cefReqCtx = requestContext != nil ? requestContext!.toCEF() : nil
        
        defer {
            cefSettings.clear()
            CEFStringPtrRelease(cefURLPtr)
            cefWinInfo.clear()
        }
        
        let cefBrowser = cef_browser_host_create_browser_sync(&cefWinInfo, cefClient, cefURLPtr, &cefSettings, cefReqCtx)
        return CEFBrowser.fromCEF(cefBrowser)
    }

    /// Returns the hosted browser object.
    public var browser: CEFBrowser? {
        // TODO: audit nonnull
        let cefBrowser = cefObject.get_browser(cefObjectPtr)
        return CEFBrowser.fromCEF(cefBrowser)
    }
    
    /// Request that the browser close. The JavaScript 'onbeforeunload' event will
    /// be fired. If |force_close| is false the event handler, if any, will be
    /// allowed to prompt the user and the user can optionally cancel the close.
    /// If |force_close| is true the prompt will not be displayed and the close
    /// will proceed. Results in a call to CefLifeSpanHandler::DoClose() if the
    /// event handler allows the close or if |force_close| is true. See
    /// CefLifeSpanHandler::DoClose() documentation for additional usage
    /// information.
    public func closeBrowser(force force: Bool) {
        cefObject.close_browser(cefObjectPtr, force ? 1 : 0)
    }

    /// Helper for closing a browser. Call this method from the top-level window
    /// close handler. Internally this calls CloseBrowser(false) if the close has
    /// not yet been initiated. This method returns false while the close is
    /// pending and true after the close has completed. See CloseBrowser() and
    /// CefLifeSpanHandler::DoClose() documentation for additional usage
    /// information. This method must be called on the browser process UI thread.
    func tryCloseBrowser() -> Bool {
        return cefObject.try_close_browser(cefObjectPtr) != 0
    }
    
    /// Set whether the browser is focused.
    public func setFocused(focused: Bool) {
        cefObject.set_focus(cefObjectPtr, focused ? 1 : 0)
    }

    /// Retrieve the window handle for this browser. If this browser is wrapped in
    /// a CefBrowserView this method should be called on the browser process UI
    /// thread and it will return the handle for the top-level native window.
    public var windowHandle: CEFWindowHandle {
        let rawHandle:UnsafeMutablePointer<Void> = cefObject.get_window_handle(cefObjectPtr)
        return Unmanaged<CEFWindowHandle>.fromOpaque(COpaquePointer(rawHandle)).takeUnretainedValue()
    }
    
    /// Retrieve the window handle of the browser that opened this browser. Will
    /// return NULL for non-popup windows or if this browser is wrapped in a
    /// CefBrowserView. This method can be used in combination with custom handling
    /// of modal windows.
    public var openerWindowHandle: CEFWindowHandle {
        let rawHandle:UnsafeMutablePointer<Void> = cefObject.get_opener_window_handle(cefObjectPtr)
        return Unmanaged<CEFWindowHandle>.fromOpaque(COpaquePointer(rawHandle)).takeUnretainedValue()
    }
    
    /// Returns true if this browser is wrapped in a CefBrowserView.
    public var hasView: Bool {
        return cefObject.has_view(cefObjectPtr) != 0
    }
    
    /// Returns the client for this browser.
    public var client: CEFClient? {
        // TODO: audit nonnull
        let cefClient = cefObject.get_client(cefObjectPtr)
        return CEFClientMarshaller.take(cefClient)
    }

    /// Returns the request context for this browser.
    public var requestContext: CEFRequestContext? {
        // TODO: audit nonnull
        let cefCtx = cefObject.get_request_context(cefObjectPtr)
        return CEFRequestContext.fromCEF(cefCtx)
    }

    /// Zoom level.
    ///
    /// :getter:
    /// Get the current zoom level. The default zoom level is 0.0. This method can
    /// only be called on the UI thread.
    ///
    /// :setter:
    /// Change the zoom level to the specified value. Specify 0.0 to reset the
    /// zoom level. If called on the UI thread the change will be applied
    /// immediately. Otherwise, the change will be applied asynchronously on the
    /// UI thread.
    public var zoomLevel: Double {
        get { return cefObject.get_zoom_level(cefObjectPtr) }
        set { cefObject.set_zoom_level(cefObjectPtr, zoomLevel) }
    }
    
    /// Call to run a file chooser dialog. Only a single file chooser dialog may be
    /// pending at any given time. |mode| represents the type of dialog to display.
    /// |title| to the title to be used for the dialog and may be empty to show the
    /// default title ("Open" or "Save" depending on the mode). |default_file_path|
    /// is the path with optional directory and/or file name component that will be
    /// initially selected in the dialog. |accept_filters| are used to restrict the
    /// selectable file types and may any combination of (a) valid lower-cased MIME
    /// types (e.g. "text/*" or "image/*"), (b) individual file extensions (e.g.
    /// ".txt" or ".png"), or (c) combined description and file extension delimited
    /// using "|" and ";" (e.g. "Image Types|.png;.gif;.jpg").
    /// |selected_accept_filter| is the 0-based index of the filter that will be
    /// selected by default. |callback| will be executed after the dialog is
    /// dismissed or immediately if another dialog is already pending. The dialog
    /// will be initiated asynchronously on the UI thread.
    public func runFileDialog(mode: CEFFileDialogMode,
                              title: String?,
                              defaultPath: String?,
                              acceptFilters: [String],
                              selectedFilterIndex: Int,
                              callback: CEFRunFileDialogCallback) {
        let cefTitle = CEFStringPtrCreateFromSwiftString(title ?? "")
        let cefPath = CEFStringPtrCreateFromSwiftString(defaultPath ?? "")
        let cefFilterList = CEFStringListCreateFromSwiftArray(acceptFilters)
        
        defer {
            CEFStringPtrRelease(cefTitle)
            CEFStringPtrRelease(cefPath)
            cef_string_list_free(cefFilterList)
        }

        cefObject.run_file_dialog(cefObjectPtr,
                                  mode.toCEF(),
                                  cefTitle,
                                  cefPath,
                                  cefFilterList,
                                  Int32(selectedFilterIndex),
                                  callback.toCEF())
    }
    
    /// Download the file at |url| using CefDownloadHandler.
    public func startDownload(url: NSURL) {
        let cefURLPtr = CEFStringPtrCreateFromSwiftString(url.absoluteString)
        defer { CEFStringPtrRelease(cefURLPtr) }
        cefObject.start_download(cefObjectPtr, cefURLPtr)
    }
    
    /// Download |image_url| and execute |callback| on completion with the images
    /// received from the renderer. If |is_favicon| is true then cookies are not
    /// sent and not accepted during download. Images with density independent
    /// pixel (DIP) sizes larger than |max_image_size| are filtered out from the
    /// image results. Versions of the image at different scale factors may be
    /// downloaded up to the maximum scale factor supported by the system. If there
    /// are no image results <= |max_image_size| then the smallest image is resized
    /// to |max_image_size| and is the only result. A |max_image_size| of 0 means
    /// unlimited. If |bypass_cache| is true then |image_url| is requested from the
    /// server even if it is present in the browser cache.
    func downloadImage(url: NSURL,
                       isFavicon: Bool,
                       maxImageSize: UInt32,
                       bypassCache: Bool,
                       callback: CEFDownloadImageCallback) {
        let cefStrPtr = CEFStringPtrCreateFromSwiftString(url.absoluteString)
        defer { CEFStringPtrRelease(cefStrPtr) }
        cefObject.download_image(cefObjectPtr,
                                 cefStrPtr,
                                 isFavicon ? 1 : 0,
                                 maxImageSize,
                                 bypassCache ? 1 : 0,
                                 callback.toCEF())
    }

    /// Print the current browser contents.
    public func print() {
        cefObject.print(cefObjectPtr)
    }

    /// Print the current browser contents to the PDF file specified by |path| and
    /// execute |callback| on completion. The caller is responsible for deleting
    /// |path| when done. For PDF printing to work on Linux you must implement the
    /// CefPrintHandler::GetPdfPaperSize method.
    func printToPDFAtPath(path: String, settings: CEFPDFPrintSettings, callback: CEFPDFPrintCallback? = nil) {
        let cefStrPtr = CEFStringPtrCreateFromSwiftString(path)
        var cefSettings = settings.toCEF()
        defer {
            CEFStringPtrRelease(cefStrPtr)
            cefSettings.clear()
        }
        cefObject.print_to_pdf(cefObjectPtr, cefStrPtr, &cefSettings, callback != nil ? callback!.toCEF() : nil)
    }
    
    /// Search for |searchText|. |identifier| can be used to have multiple searches
    /// running simultaniously. |forward| indicates whether to search forward or
    /// backward within the page. |matchCase| indicates whether the search should
    /// be case-sensitive. |findNext| indicates whether this is the first request
    /// or a follow-up. The CefFindHandler instance, if any, returned via
    /// CefClient::GetFindHandler will be called to report find results.
    public func find(identifier: CEFFindIdentifier, searchText: String, forward: Bool, caseSensitive: Bool, findNext: Bool) {
        let cefStrPtr = CEFStringPtrCreateFromSwiftString(searchText)
        defer { CEFStringPtrRelease(cefStrPtr) }
        cefObject.find(cefObjectPtr, identifier, cefStrPtr, forward ? 1 : 0, caseSensitive ? 1 : 0, findNext ? 1 : 0)
    }
    
    /// Cancel all searches that are currently going on.
    public func stopFinding(clearSelection clearSelection: Bool) {
        cefObject.stop_finding(cefObjectPtr, clearSelection ? 1 : 0)
    }
    
    /// Open developer tools (DevTools) in its own browser. The DevTools browser
    /// will remain associated with this browser. If the DevTools browser is
    /// already open then it will be focused, in which case the |windowInfo|,
    /// |client| and |settings| parameters will be ignored. If |inspect_element_at|
    /// is non-empty then the element at the specified (x,y) location will be
    /// inspected. The |windowInfo| parameter will be ignored if this browser is
    /// wrapped in a CefBrowserView.
    public func showDevTools(windowInfo: CEFWindowInfo,
                             client: CEFClient,
                             settings: CEFBrowserSettings,
                             inspectionPoint: NSPoint?) {
        var cefPointPtr: UnsafeMutablePointer<cef_point_t> = nil
        if let inspectionPoint = inspectionPoint {
            cefPointPtr = UnsafeMutablePointer<cef_point_t>.alloc(1)
            defer { cefPointPtr.destroy(1) }
            cefPointPtr.initialize(inspectionPoint.toCEF())
        }

        var cefSettings = settings.toCEF()
        var cefWinInfo = windowInfo.toCEF()
        defer {
            cefSettings.clear()
            cefWinInfo.clear()
        }
        cefObject.show_dev_tools(cefObjectPtr, &cefWinInfo, client.toCEF(), &cefSettings, cefPointPtr)
    }
    
    /// Explicitly close the associated DevTools browser, if any.
    public func closeDevTools() {
        cefObject.close_dev_tools(cefObjectPtr)
    }

    // Returns true if this browser currently has an associated DevTools browser.
    // Must be called on the browser process UI thread.
    public var hasDevTools: Bool {
        return cefObject.has_dev_tools(cefObjectPtr) != 0
    }
    
    /// Retrieve a snapshot of current navigation entries as values sent to the
    /// specified visitor. If |current_only| is true only the current navigation
    /// entry will be sent, otherwise all navigation entries will be sent.
    public func enumerateNavigationEntriesUsingVisitor(visitor: CEFNavigationEntryVisitor, currentOnly: Bool) {
        cefObject.get_navigation_entries(cefObjectPtr, visitor.toCEF(), currentOnly ? 1 : 0)
    }
    
    /// Whether mouse cursor change is disabled.
    public var mouseCursorChangeDisabled: Bool {
        get { return cefObject.is_mouse_cursor_change_disabled(cefObjectPtr) != 0 }
        set { cefObject.set_mouse_cursor_change_disabled(cefObjectPtr, newValue ? 1 : 0) }
    }
    
    /// If a misspelled word is currently selected in an editable node calling
    /// this method will replace it with the specified |word|.
    public func replaceMisspelling(replacementWord: String) {
        let cefStrPtr = CEFStringPtrCreateFromSwiftString(replacementWord)
        defer { CEFStringPtrRelease(cefStrPtr) }
        cefObject.replace_misspelling(cefObjectPtr, cefStrPtr)
    }

    /// Add the specified |word| to the spelling dictionary.
    public func addWordToDictionary(word: String) {
        let cefStrPtr = CEFStringPtrCreateFromSwiftString(word)
        defer { CEFStringPtrRelease(cefStrPtr) }
        cefObject.add_word_to_dictionary(cefObjectPtr, cefStrPtr)
    }
    
    /// Returns true if window rendering is disabled.
    public var isWindowRenderingDisabled: Bool {
        return cefObject.is_window_rendering_disabled(cefObjectPtr) != 0
    }
    
    /// Notify the browser that the widget has been resized. The browser will first
    /// call CefRenderHandler::GetViewRect to get the new size and then call
    /// CefRenderHandler::OnPaint asynchronously with the updated regions. This
    /// method is only used when window rendering is disabled.
    public func notifyWasResized() {
        cefObject.was_resized(cefObjectPtr)
    }
    
    /// Notify the browser that it has been hidden or shown. Layouting and
    /// CefRenderHandler::OnPaint notification will stop when the browser is
    /// hidden. This method is only used when window rendering is disabled.
    public func notifyWasHidden(hidden: Bool) {
        cefObject.was_hidden(cefObjectPtr, hidden ? 1 : 0)
    }

    /// Send a notification to the browser that the screen info has changed. The
    /// browser will then call CefRenderHandler::GetScreenInfo to update the
    /// screen information with the new values. This simulates moving the webview
    /// window from one display to another, or changing the properties of the
    /// current display. This method is only used when window rendering is
    /// disabled.
    public func notifyScreenInfoChanged() {
        cefObject.notify_screen_info_changed(cefObjectPtr)
    }

    /// Invalidate the view. The browser will call CefRenderHandler::OnPaint
    /// asynchronously. This method is only used when window rendering is
    /// disabled.
    public func invalidate(element: CEFPaintElementType) {
        cefObject.invalidate(cefObjectPtr, element.toCEF())
    }

    /// Send a key event to the browser.
    public func sendKeyEvent(event: CEFKeyEvent) {
        var cefEvent = event.toCEF()
        cefObject.send_key_event(cefObjectPtr, &cefEvent)
    }

    /// Send a mouse click event to the browser. The |x| and |y| coordinates are
    /// relative to the upper-left corner of the view.
    public func sendMouseClickEvent(event: CEFMouseEvent, type: CEFMouseButtonType, mouseUp: Bool, clickCount: Int) {
        var cefEvent = event.toCEF()
        cefObject.send_mouse_click_event(cefObjectPtr, &cefEvent, type.toCEF(), mouseUp ? 1 : 0, Int32(clickCount))
    }

    /// Send a mouse move event to the browser. The |x| and |y| coordinates are
    /// relative to the upper-left corner of the view.
    public func sendMouseMoveEvent(event: CEFMouseEvent, mouseLeave: Bool) {
        var cefEvent = event.toCEF()
        cefObject.send_mouse_move_event(cefObjectPtr, &cefEvent, mouseLeave ? 1 : 0)
    }

    /// Send a mouse wheel event to the browser. The |x| and |y| coordinates are
    /// relative to the upper-left corner of the view. The |deltaX| and |deltaY|
    /// values represent the movement delta in the X and Y directions respectively.
    /// In order to scroll inside select popups with window rendering disabled
    /// CefRenderHandler::GetScreenPoint should be implemented properly.
    public func sendMouseWheelEvent(event: CEFMouseEvent, deltaX: Int, deltaY: Int) {
        var cefEvent = event.toCEF()
        cefObject.send_mouse_wheel_event(cefObjectPtr, &cefEvent, Int32(deltaX), Int32(deltaY))
    }
    
    /// Send a focus event to the browser.
    public func sendFocusEvent(focus: Bool) {
        cefObject.send_focus_event(cefObjectPtr, focus ? 1 : 0)
    }
    
    /// Send a capture lost event to the browser.
    public func sendCaptureLostEvent() {
        cefObject.send_capture_lost_event(cefObjectPtr)
    }

    /// Notify the browser that the window hosting it is about to be moved or
    /// resized. This method is only used on Windows and Linux.
    public func notifyMoveOrResizeStarted() {
        cefObject.notify_move_or_resize_started(cefObjectPtr)
    }
    
    /// The maximum rate in frames per second (fps) that CefRenderHandler::
    /// OnPaint will be called for a windowless browser. The actual fps may be
    /// lower if the browser cannot generate frames at the requested rate. The
    /// minimum value is 1 and the maximum value is 60 (default 30). This method
    /// can only be called on the UI thread. Can also be set at browser creation
    /// via CefBrowserSettings.windowless_frame_rate.
    public var windowlessFrameRate: Int {
        get { return Int(cefObject.get_windowless_frame_rate(cefObjectPtr)) }
        set { cefObject.set_windowless_frame_rate(cefObjectPtr, Int32(newValue)) }
    }
    
    /// Get the NSTextInputContext implementation for enabling IME on Mac when
    /// window rendering is disabled.
    public var textInputContext: CEFTextInputContext {
        let rawHandle:UnsafeMutablePointer<Void> = cefObject.get_nstext_input_context(cefObjectPtr)
        return Unmanaged<CEFTextInputContext>.fromOpaque(COpaquePointer(rawHandle)).takeUnretainedValue()
    }

    /// Handles a keyDown event prior to passing it through the NSTextInputClient
    /// machinery.
    public func handleKeyEventBeforeTextInputClient(event: CEFEventHandle) {
        let rawEvent = UnsafeMutablePointer<Void>(Unmanaged<CEFEventHandle>.passUnretained(event).toOpaque())
        cefObject.handle_key_event_before_text_input_client(cefObjectPtr, rawEvent)
    }
    
    /// Performs any additional actions after NSTextInputClient handles the event.
    public func handleKeyEventAfterTextInputClient(event: CEFEventHandle) {
        let rawEvent = UnsafeMutablePointer<Void>(Unmanaged<CEFEventHandle>.passUnretained(event).toOpaque())
        cefObject.handle_key_event_after_text_input_client(cefObjectPtr, rawEvent)
    }

    /// Call this method when the user drags the mouse into the web view (before
    /// calling DragTargetDragOver/DragTargetLeave/DragTargetDrop).
    /// |drag_data| should not contain file contents as this type of data is not
    /// allowed to be dragged into the web view. File contents can be removed using
    /// CefDragData::ResetFileContents (for example, if |drag_data| comes from
    /// CefRenderHandler::StartDragging).
    /// This method is only used when window rendering is disabled.
    public func dragTargetDragEnter(dragData: CEFDragData, event: CEFMouseEvent, operationMask: CEFDragOperationsMask) {
        let cefDragData = dragData.toCEF()
        var cefEvent = event.toCEF()
        cefObject.drag_target_drag_enter(cefObjectPtr, cefDragData, &cefEvent, operationMask.toCEF())
    }
    
    /// Call this method each time the mouse is moved across the web view during
    /// a drag operation (after calling DragTargetDragEnter and before calling
    /// DragTargetDragLeave/DragTargetDrop).
    /// This method is only used when window rendering is disabled.
    public func dragTargetDragOver(event: CEFMouseEvent, operationMask: CEFDragOperationsMask) {
        var cefEvent = event.toCEF()
        cefObject.drag_target_drag_over(cefObjectPtr, &cefEvent, operationMask.toCEF())
    }
    
    /// Call this method when the user drags the mouse out of the web view (after
    /// calling DragTargetDragEnter).
    /// This method is only used when window rendering is disabled.
    public func dragTargetDragLeave() {
        cefObject.drag_target_drag_leave(cefObjectPtr)
    }
    
    /// Call this method when the user completes the drag operation by dropping
    /// the object onto the web view (after calling DragTargetDragEnter).
    /// The object being dropped is |drag_data|, given as an argument to
    /// the previous DragTargetDragEnter call.
    /// This method is only used when window rendering is disabled.
    public func dragTargetDrop(event: CEFMouseEvent) {
        var cefEvent = event.toCEF()
        cefObject.drag_target_drop(cefObjectPtr, &cefEvent)
    }
    
    /// Call this method when the drag operation started by a
    /// CefRenderHandler::StartDragging call has ended either in a drop or
    /// by being cancelled. |x| and |y| are mouse coordinates relative to the
    /// upper-left corner of the view. If the web view is both the drag source
    /// and the drag target then all DragTarget* methods should be called before
    /// DragSource* mthods.
    /// This method is only used when window rendering is disabled.
    public func dragSourceEndedAt(x: Int, y: Int, operationMask: CEFDragOperationsMask) {
        cefObject.drag_source_ended_at(cefObjectPtr, Int32(x), Int32(y), operationMask.toCEF())
    }
    
    /// Call this method when the drag operation started by a
    /// CefRenderHandler::StartDragging call has completed. This method may be
    /// called immediately without first calling DragSourceEndedAt to cancel a
    /// drag operation. If the web view is both the drag source and the drag
    /// target then all DragTarget* methods should be called before DragSource*
    /// mthods.
    /// This method is only used when window rendering is disabled.
    public func dragSourceSystemDragEnded() {
        cefObject.drag_source_system_drag_ended(cefObjectPtr)
    }

}


public extension CEFBrowserHost {
    /// Retrieve a snapshot of current navigation entries as values sent to the
    /// specified visitor. If |current_only| is true only the current navigation
    /// entry will be sent, otherwise all navigation entries will be sent.
    public func enumerateNavigationEntries(currentOnly: Bool, block: CEFNavigationEntryVisitorVisitBlock) {
        enumerateNavigationEntriesUsingVisitor(CEFNavigationEntryVisitorBridge(block: block), currentOnly: currentOnly)
    }

    /// Call to run a file chooser dialog. Only a single file chooser dialog may be
    /// pending at any given time. |mode| represents the type of dialog to display.
    /// |title| to the title to be used for the dialog and may be empty to show the
    /// default title ("Open" or "Save" depending on the mode). |default_file_path|
    /// is the path with optional directory and/or file name component that will be
    /// initially selected in the dialog. |accept_filters| are used to restrict the
    /// selectable file types and may any combination of (a) valid lower-cased MIME
    /// types (e.g. "text/*" or "image/*"), (b) individual file extensions (e.g.
    /// ".txt" or ".png"), or (c) combined description and file extension delimited
    /// using "|" and ";" (e.g. "Image Types|.png;.gif;.jpg").
    /// |selected_accept_filter| is the 0-based index of the filter that will be
    /// selected by default. |callback| will be executed after the dialog is
    /// dismissed or immediately if another dialog is already pending. The dialog
    /// will be initiated asynchronously on the UI thread.
    public func runFileDialog(mode: CEFFileDialogMode,
                              title: String?,
                              defaultPath: String?,
                              acceptFilters: [String],
                              selectedFilterIndex: Int,
                              block: CEFRunFileDialogCallbackOnFileDialogDismissedBlock) {
        runFileDialog(mode,
                      title: title,
                      defaultPath: defaultPath,
                      acceptFilters: acceptFilters,
                      selectedFilterIndex: selectedFilterIndex,
                      callback: CEFRunFileDialogCallbackBridge(block: block))
    }

    /// Download |image_url| and execute |callback| on completion with the images
    /// received from the renderer. If |is_favicon| is true then cookies are not
    /// sent and not accepted during download. Images with density independent
    /// pixel (DIP) sizes larger than |max_image_size| are filtered out from the
    /// image results. Versions of the image at different scale factors may be
    /// downloaded up to the maximum scale factor supported by the system. If there
    /// are no image results <= |max_image_size| then the smallest image is resized
    /// to |max_image_size| and is the only result. A |max_image_size| of 0 means
    /// unlimited. If |bypass_cache| is true then |image_url| is requested from the
    /// server even if it is present in the browser cache.
    func downloadImage(url: NSURL,
                       isFavicon: Bool,
                       maxImageSize: UInt32,
                       bypassCache: Bool,
                       block: CEFDownloadImageCallbackOnDownloadImageFinishedBlock) {
        downloadImage(url,
                      isFavicon: isFavicon,
                      maxImageSize: maxImageSize,
                      bypassCache: bypassCache,
                      callback: CEFDownloadImageCallbackBridge(block: block))
    }

    /// Print the current browser contents to the PDF file specified by |path| and
    /// execute |callback| on completion. The caller is responsible for deleting
    /// |path| when done. For PDF printing to work on Linux you must implement the
    /// CefPrintHandler::GetPdfPaperSize method.
    func printToPDFAtPath(path: String, settings: CEFPDFPrintSettings, block: CEFPDFPrintCallbackOnPDFPrintFinishedBlock) {
        printToPDFAtPath(path, settings: settings, callback: CEFPDFPrintCallbackBridge(block: block))
    }
}

