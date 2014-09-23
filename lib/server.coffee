Accounts.onCreateUser (options, user) ->
  if options.profile
    options.profile.color = share.getRandomColor()
  else
    options.profile = {
      color: share.getRandomColor()
    }

  user.profile = options.profile

  return user

Accounts.addAutopublishFields
  loggedInUser: ['profile']
  forOtherUsers: ['profile']
