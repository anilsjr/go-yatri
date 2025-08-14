# Goyatri

Goyatri is a cross-platform Flutter application for transportation selection and location management, built with a clean architecture. It supports both Android and iOS.

## Features

- Select pickup location via search, recent, favorite, or map
- View/manage recent and favorite locations
- Use current GPS location for pickup
- Map-based location selection with custom markers
- Draw paths on map using polylines
- Firebase authentication and notifications
- Modern UI (Material Design)

## Demo Screenshots

| Home Page                          | Login Page                           | Menu Page                          |
| ---------------------------------- | ------------------------------------ | ---------------------------------- |
| ![Home](demo-images/home_page.jpg) | ![Login](demo-images/login_page.jpg) | ![Menu](demo-images/menu_page.jpg) |

| Notification Alert                                  | Pickup Page                            | Select Location on Map                                     | Splash Page                            |
| --------------------------------------------------- | -------------------------------------- | ---------------------------------------------------------- | -------------------------------------- |
| ![Notification](demo-images/notification_alert.jpg) | ![Pickup](demo-images/pickup_page.jpg) | ![Select Location](demo-images/select_location_on_map.jpg) | ![Splash](demo-images/splash_page.jpg) |

## Tech Stack & Packages

- **Clean Architecture**: Organized by feature, core, services, storage
- **GetX**: Navigation
- **Provider**: State management/controllers
- **permission_handler**: Request location permissions
- **google_maps_flutter**: Map integration
- **flutter_polyline_points**: Draw paths on map
- **Custom Markers**: For map locations (see `assets/icons/`)
- **firebase_core & firebase_auth**: Authentication
- **flutter_local_notifications**: Local notifications

## Folder Structure

```
lib/
  main.dart
  features/
    location/
      data/
      domain/
      presentation/
    ...
  core/
  services/
  storage/
assets/
  icons/
  map/
  ...
android/
ios/
web/
windows/
linux/
macos/
test/
```

- **assets/**: Images, icons, custom map markers
- **features/**: Feature modules (location, routes, etc.)
- **core/**: Core utilities
- **services/**: Service classes
- **storage/**: Persistence

## Usage

- Search/select pickup location
- Use current location (with permission)
- View recent/favorite locations
- Select location on map (custom markers, polylines)
- Auth via Firebase
- Receive notifications

## Contributing

Contributions are welcome! Please open issues or submit pull requests for improvements.

## License

This project is licensed under the MIT License.
