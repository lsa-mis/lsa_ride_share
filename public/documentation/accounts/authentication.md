# Authentication:
[Home](./README.md) / [Accounts](accounts/README.md) / [Requesting Access](accounts/requesting_access.md)

ModelRails supports three modes of authentication; Shibboleth , GoogleOAuth and Active Directory. Utilizing these methods allows us to provide authentication without storing passwords in our applications.

>  **Important:** *Never store passwords in the application database unless it cannot be avoided. Utilize OAuth or Shibbolith instead. **Encrypt all the things!!!***

These methods of authentication can be used individually or in conjunction with one another, depending on the use case. Users can choose which every login method they prefer to use (provided the application is configured to support it), and the application will log them into the same personal account. This is convenient if a user forgets which one to use with which app. 

> Determining permissions based on the manner with which a user signed in is **strongly discouraged**! *Avoiding this approach allows us to change the login options in the future without having to rewrite a bunch of code.*


### GoogleOAuth
  == link to GoogleOAuth documentation
  GoogleOAuth can be used as a Single Sign On option, and logins can be restricted to the umich.edu domain. 

  This option is the easiest to implement since it does not require coordination with other teams. (Developers can set this method up without engaging a human.)

### Shibboleth 
  == link to shibboleth documenation

### Active Directory{} 
  == link to Active Directory documentation 

<img 
  style="display: block; 
          margin-left: auto;
          margin-right: auto;
          width: 20%;"
  src="https://markdown.land/wp-content/uploads/2021/06/markdown-512px.png" 
  alt="Our logo">
</img>