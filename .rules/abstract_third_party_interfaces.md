# Abstract Third-Party Interfaces With Wrappers

Third-party services change. Your domain concepts don't. Wrap external APIs in abstractions that reflect your application's language.

## The Rule

Never call third-party APIs directly throughout your codebase. Create wrapper classes that:

- Express your domain's terminology
- Isolate the integration to a single location
- Return domain-relevant data structures

## Examples

```ruby
# Bad - third-party API used directly throughout the codebase
class ProfilesController
  def show
    @coordinates = GoogleMaps::API::Geocoding.fetch(address)
  end
end

class VenuesController
  def create
    coordinates = GoogleMaps::API::Geocoding.fetch(params[:address])
  end
end
```

```ruby
# Good - wrapped in a domain-specific abstraction
module Maps
  module Geocoding
    class Locations
      def self.coordinates_for(address)
        response = GoogleMaps::API::Geocoding.fetch(address)
        Coordinates.new(lat: response.lat, lng: response.lng)
      end
    end
  end
end

class ProfilesController
  def show
    @coordinates = Maps::Geocoding::Locations.coordinates_for(address)
  end
end
```

## Benefits

- **Swappable providers**: Change from Google Maps to Mapbox without touching application code
- **Consistent interface**: Your app always receives the same data structure
- **Testability**: Mock your wrapper, not the third-party gem
- **Domain clarity**: Code reads in terms of what it does, not which service it uses
