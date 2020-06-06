Observable

 https://angular.io/guide/rx-library
 https://angular.io/guide/observables#subscribing
 Observable

//  Basic usage and terms

//  Observables provide support for passing messages between publishers and subscribers in your application

//  Observables are declarative—that is, you define a function for publishing values, but it is not executed until a consumer subscribes to it. 
//  The subscribed consumer then receives notifications until the function "subscriber" completes, or until they unsubscribe.


// Observer:
// An object for receiving observable notifications implements the Observer interface.
// Difines what we want to do with the rcvd data/notifications.

observer = {
			next:(data)=>{ console.log(data)  } ,        //doSomething with the rcvd data in next property
			error: (err)=>{ err handling},
			complete: () => {}
		}


// Publisher/Producer:  må returnere unsubscribe()??
// The Publisher/Producer function defines how to obtain or generate values to be published.

// This function runs when subscribe() is called
function Produce(observer) {
  // synchronously deliver 1, 2, and 3, then complete
  observer.next(1);
  observer.next(2);
  observer.next(3);
  observer.complete();
  //return ()=>{}  unsubscribe fn
}


// *****************************************************************************

// Usually:

// The receiver/consumer implements
	observer = {
				next:      required property
				error:     optional property
				complete:  optional property
			}

	const myObservable = new Observable()
	myObservable.subscribe(  observer  )



// The Publisher/Producer implements

	function produce( observer ){...}

	OR

	Observable.of( data )

// *****************************************************************************



/* In order to show how subscribing works, we need to create a new observable. There is a constructor that you use to create new instances,
but for illustration, we can use some static methods on the Observable class that create simple observables of frequently used types:

    Observable.of(...items)—Returns an Observable instance that synchronously delivers the values provided as arguments.
    Observable.from(iterable)—Converts its argument to an Observable instance. This method is commonly used to convert an array to an observable.
*/
Observable.from([1,2,3]).subscribe(x => console.log(x)); //prints the elements one by one.
// Observable.from will accept an argument that is a subscribable object, a Promise, an Observable-like, an Array, an iterable or an array-like object to be converted

Observable.of(1,2,3).subscribe(x => console.log(x));   //prints the elements one by one.
Observable.of([1,2,3]).subscribe(x => console.log(x)); //would print the whole array at once
// There is no similar behaviour for Observable.of - which always accepts only values and performs no conversion

// *****************************************************************************
// *****************************************************************************

// Create simple observable that emits three values
const myObservable = Observable.of(1, 2, 3);

// Create observer object
const myObserver = {
  next: x => console.log('Observer got a next value: ' + x),
  error: err => console.error('Observer got an error: ' + err),
  complete: () => console.log('Observer got a complete notification'),
};

// Execute with the observer object
myObservable.subscribe(myObserver);
// Logs:
// Observer got a next value: 1
// Observer got a next value: 2
// Observer got a next value: 3
// Observer got a complete notification




// ****************************** The same example, but with subscriber ******************************


// This function  (Publisher/Producer) runs when subscribe() is called
function sequenceProducer(observer) {
  // synchronously deliver 1, 2, and 3, then complete
  observer.next(1);
  observer.next(2);
  observer.next(3);
  observer.complete();

  // unsubscribe function doesn't need to do anything in this
  // because values are delivered synchronously
  return {unsubscribe() {}};
}

// Create a new Observable that will deliver the above sequence
const sequence = new Observable(sequenceProducer);

// execute the Observable and print the result of each notification
sequence.subscribe({
  next(num) { console.log(num); },
  complete() { console.log('Finished sequence'); }
});

// Logs:
// 1
// 2
// 3
// Finished sequence


// *****************************************************************************
// *************************** TYPESCRIPT **************************************
// *****************************************************************************

function fromEvent(target, eventName) {

  // This function  (Publisher/Producer) runs when subscribe() is called
  const porduceFn = (observer) => {

    // Add the event handler to the target
    target.addEventListener(eventName, (e) => observer.next(e)  );

    return () => {
      // unsubscribe
      // Deattach the event handler from the target
      target.removeEventListener(eventName, handler);
    };
  }

  return new Observable(  porduceFn  );
}




const ESC_KEY = 27;
const nameInput = document.getElementById('name') as HTMLInputElement;


const myObserver = {
	next: (e: KeyboardEvent) => { if (e.keyCode === ESC_KEY)  nameInput.value = ''; }
}

const subscription = fromEvent( nameInput, 'keydown' )  // instance of Observable
subscription.subscribe(myObserver);




// ******************************  Vi kan omskrive "formEvent" til å bli sånn ******************************

  // Publisher/Producer function runs when subscribe() is called
  const porduceFn = (target, eventName)=> (observer) => {

    // Add the event handler to the target
    target.addEventListener(eventName, (e) => observer.next(e)  );

    return () => {
      // unsubscribe
      // Deattach the event handler from the target
      target.removeEventListener(eventName, handler);
    };
  }


function fromEvent(target, eventName) {
  return new Observable(  porduceFn(target, eventName)  );
}



// ********************************ren JS*********************************************
const node = document.getElementById('input');
const p = document.getElementById('p');


const producer = (element, eventName)=>( observer) => {
    const callback = (event) => observer.next(event);
    element.addEventListener(eventName, callback, false);
    return () => element.removeEventListener(eventName, callback, false);
}
  
function Observable(subscribe) {
  this.subscribe = subscribe;
}

Observable.fromEvent = (element, eventName) => {
  return new Observable(producer(element, eventName));
};





const myInputObservable = Observable.fromEvent(node, 'keydown');

const observer = {
  next: (event) => {
  if(event.keyCode === 27)
    node.value = '';
  }
}

myInputObservable.subscribe(observer);
