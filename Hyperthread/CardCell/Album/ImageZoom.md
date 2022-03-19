# UI Goals
Requirements for a modal image view
- Large images are initially completely in frame
- Small images are initially not expanded beyond their intrinsic size
    - additionally, they are centered within the viewport

- When presented and dismissed, images morph from their original positions
    - similar to SwiftUI's `matchedGeometryEffect`
- Dismissal should be interactive

- Both large and small images can be zoomed into
- Double tapping toggles zoom in / out
- When panning across a zoomed image, there should be no large empty spaces on screen 

As of 22.03.17, we have (mostly) achieved this!
