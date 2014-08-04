#This config is for a more generalised server, can be used with Wordpress but also other sites
sub vcl_recv {
 
  # Many requests contain Accept-Encoding HTTP headers. We standardize and remove these when unnecessary to make it easier to cache requests
  if (req.http.Accept-Encoding) {
    # If the request URL has any of these extensions, remove the Accept-Encoding header as it is meaningless
    if (req.url ~ ".(gif|jpg|jpeg|swf|flv|mp3|mp4|pdf|ico|png|gz|tgz|bz2)$") {
      remove req.http.Accept-Encoding;
    # If the Accept-Encoding contains 'gzip' standardize it.
    } elsif (req.http.Accept-Encoding ~ "gzip") {
      set req.http.Accept-Encoding = "gzip";
    # If the Accept-Encoding contains 'deflate' standardize it.
    } elsif (req.http.Accept-Encoding ~ "deflate") {
      set req.http.Accept-Encoding = "deflate";
    # If the Accept-Encoding header isn't matched above, remove it.
    } else {
      remove req.http.Accept-Encoding;
    }
  }
 
  # Many requests contain cookies on requests for resources which cookies don't matter -- such as static images or documents.
  if (req.url ~ ".(gif|jpg|jpeg|swf|css|js|flv|mp3|mp4|pdf|ico|png)$") {
    # Remove cookies from these resources, and remove any attached query strings.
    unset req.http.cookie;
    set req.url = regsub(req.url, "?.$", "");
  }
 
  # Certain cookies (such as for Google Analytics) are client-side only, and don't matter to our web application.
  if (req.http.cookie) {
    # If a request contains cookies we care about, don't cache it (return pass).
    if (req.http.cookie ~ "(mycookie1|important-cookie|myidentification-cookie)") {
      return(pass);
    } else {
    # Otherwise, remove the cookie.
      unset req.http.cookie;
    }
  }
}

sub vcl_fetch {
 
  # If the URL is for our login page, we never want to cache the page itself.
  if (req.url ~ "/login" || req.url ~ "preview=true") {
    # But, we can cache the fact that we don't want this page cached (return hit_for_pass).
    return (hit_for_pass);
  }
 
  # If the URL is for our non-admin pages, we always want them to be cached.
  if ( ! (req.url ~ "(/admin|/login|/administrator)") ) {
    # Remove cookies...
    unset beresp.http.set-cookie;
    # Cache the page for 1 day
    set beresp.ttl = 86400s;
    # Remove existing Cache-Control headers...
    remove beresp.http.Cache-Control;
    # Set new Cache-Control headers for brwosers to store cache for 7 days
    set beresp.http.Cache-Control = "public, max-age=604800";
  }
 
  # If the URL is for one of static images or documents, we always want them to be cached.
  if (req.url ~ ".(gif|jpg|jpeg|swf|css|js|flv|mp3|mp4|pdf|ico|png)$") {
    # Remove cookies...
    unset beresp.http.set-cookie;
    # Cache the page for 365 days.
    set beresp.ttl = 365d;
    # Remove existing Cache-Control headers...
    remove beresp.http.Cache-Control;
    # Set new Cache-Control headers for browser to store cache for 7 days
    set beresp.http.Cache-Control = "public, max-age=604800";
  }
}

sub vcl_deliver {
 
  # Sometimes it's nice to see when content has been served from the cache.  
  if (obj.hits > 0) {
    # If the object came from the cache, set an HTTP header to say so
    set resp.http.X-Cache = "HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }
 
  # For security and asthetic reasons, remove some HTTP headers before final delivery...
  remove resp.http.Server;
  remove resp.http.X-Powered-By;
  remove resp.http.Via;
  remove resp.http.X-Varnish;
}
