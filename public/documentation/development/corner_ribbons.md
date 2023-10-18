# Corner Ribbons
[Home](./README.md) / [Development](development/README.md)

Corner Ribbons can be a helpful way to flag pages of your site. The Model Rails app template has them preconfigured in the ```@layer utilities {}``` section of the``` application.tailwind.css``` file. 

To add a corner ribbon to your site, wrap the element in a div with the class `corner-ribbon` and one of the following classes:

``` css
top-left 
top-right  /* default */
bottom-left 
bottom-right 
``` 

If you only use the class 'corner-ribbon' without a placement class, it will default to the top right corner.

## Example

``` html  
<div class="corner-ribbon" >
  Top Right (default)
  </div>
```

<div class="bg-red-700 text-red-50 pt-1 h-8 w-48 rotate-45 text-center    z-50 shadow-2xl absolute right-0 -mt-24  ">Top Right (default) </div>


## Example
To place the ribbon in the top left corner, use the class `top-left`
``` html
<div class="corner-ribbon top-left" >
  Top Left
</div>

```

<div class="bg-red-700 text-red-50 pt-1 h-8 w-56 -rotate-45 text-center    z-50 shadow-2xl absolute left-52 -mt-24  ">Top Left  </div>



## Example
To override the styling,add tailwind classes to the div directly
``` html
<div class="corner-ribbon bottom-right bg-green-800 text-2xl text-green-50" >
  Bottom Right - Green
</div>

```
<div class="bg-green-800 text-green-50 pt-1 h-8 w-48 rotate-45 text-center    z-50 shadow-2xl absolute right-0 -mt-24  ">Top Right (green) </div>