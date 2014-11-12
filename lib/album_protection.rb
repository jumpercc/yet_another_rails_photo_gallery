module AlbumProtection
  def self.authorize( album, cookies )
    if User.autorized? cookies
      nil
    else
      if album.protected?
        protected_album = get_protected_root album
        if cookies.signed[:albums].nil? \
          || !cookies.signed[:albums].has_key?( protected_album.name )
          protected_album
        else
          nil
        end
      else
        nil
      end
    end
  end

  def self.authentify( album, password, cookies )
    album = get_protected_root album
    pass_hash = Album.hash_password password
    if pass_hash == album.password_hash
      value = cookies.signed[:albums].nil? \
        ? {}
        : cookies.signed[:albums]
      value[album.name] = 1
      cookies.signed[:albums] = {
        value: value,
        secure: !Rails.env.development?,
      }
      true
    else
      false
    end
  end

  private

  def self.get_protected_root(album)
    protected_album = nil

    while !album.nil?
      if album.protected?
        protected_album = album
      else
        break
      end
      album = album.parent
    end

    protected_album
  end
end
