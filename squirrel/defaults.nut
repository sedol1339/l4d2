// Squirrel functions found in crash .mdmp file
// same can be found here:
// https://github.com/stanriders/hl2-asw-port/blob/master/src/game/server/vscript_server.nut
// https://github.com/stanriders/hl2-asw-port/blob/master/src/game/server/spawn_helper.nut
// https://github.com/stanriders/hl2-asw-port/blob/master/src/game/server/point_template.cpp
// https://github.com/Enhanced-Source-Project/Enhanced-Source/blob/master/src/game/server/spawn_helper_nut.h

//========== Copyright © 2008, Valve Corporation, All rights reserved. ========
//
// Purpose: Script initially run after squirrel VM is initialized
//
//=============================================================================

//-----------------------------------------------------------------------------
// General
//-----------------------------------------------------------------------------

realPrint <- print
print_indent <- 0

function print( text )
{
	for ( local i = print_indent; i > 0; --i )
	{
		realPrint( "  " )
	}
	realPrint( text )
}

function printl( text )
{
	return print( text + "\n" );
}

function Msg( text )
{
	return print( text );
}

function Assert( b, msg = null )
{
	if ( b )
		return;
		
	if ( msg != null )
	{
		throw "Assertion failed: " + msg;
	}
	else
	{
		throw "Assertion failed";
	}
}

//-----------------------------------------------------------------------------

function FindCircularReference( target )
{
	local visits = {}
	local result = false
	
	function RecursiveSearch( current )
	{
		if ( current in visits )
		{
			return;
		}
		visits[current] <- true;
		
		foreach( key, val in current )
		{
			if ( val == target && !IsWeakref( target, key ) )
			{
				print( "    Circular reference to " + target.tostring() + " in key " + key.tostring() + " slot " + val.tostring() + " of object " + current.tostring() + "\n" )
				result = true
			}
			else if ( typeof( val ) == "table" || typeof( val ) == "array" || typeof( val ) == "instance" )
			{
				if ( !IsWeakref( target, key ) )
				{
					RecursiveSearch( val )
				}
			}
		}
	}
	
	if ( typeof( target ) == "table" || typeof( target ) == "array" || typeof( target ) == "instance" )
		RecursiveSearch( target );
		
	return result
}

function FindCircularReferences( resurrecteds )
{
	printl( "Circular references:" )

	if ( resurrecteds == null )
	{
		printl( "    None");
		return
	}
	
	if ( typeof( resurrecteds ) != "array" )
	{
		throw "Bad input to FindCircularReference"
	}

	foreach( val in resurrecteds )
	{
		FindCircularReference( val )
	}
	
	print("Resurrected objects: ")
	DumpObject( resurrecteds );
}	

//-----------------------------------------------------------------------------

function ScriptDebugDumpKeys( name, table = null )
{
	if ( table == null )
	{
		table = getroottable()
	}

	if ( name == "" )
	{
		printl( table.tostring() + "\n{" );
	}
	else
	{
		printl( "Find \"" + name + "\"\n{" );
	}
	
	local function PrintKey( keyPath, key, value )
	{
		printl( "    " + keyPath + " = " + value ); 
	}
	
	ScriptDebugIterateKeys( name, PrintKey, table );
	
	printl( "}" );
}

//-----------------------------------------------------------------------------

function ScriptDebugIterateKeys( name, callback, table = null )
{
	local visits = {}
	local pattern;
	
	local function MatchRegexp( keyPath )
	{
		return pattern.match( keyPath );
	}
	
	local function MatchSubstring( keyPath )
	{
		return keyPath.find( name ) != null;
	}

	local function MatchAll( keyPath )
	{
		return true;
	}
	
	local matchFunc;
	
	if ( table == null )
	{
		table = getroottable()
	}

	if ( name == "" )
	{
		matchFunc = MatchAll
	}
	else if ( name[0] == '#' ) // exact
	{
		pattern = regexp( "^" + name + "$" )
		matchFunc = MatchRegexp
	}
	else if ( name[0] == '@' ) // regexp
	{
		pattern = regexp( name.slice( 1 ) )
		matchFunc = MatchRegexp
	}
	else // general
	{
		matchFunc = MatchSubstring
	}
		
	ScriptDebugIterateKeysRecursive( matchFunc, null, table, visits, callback );
}

//-----------------------------------------------------------------------------

function ScriptDebugIterateKeysRecursive( matchFunc, path, current, visits, callback )
{
	if ( ! ( current in visits ) )
	{
		visits[current] <- true
		
		foreach( key, value in current )
		{
			if ( typeof(key) == "string" )
			{
				local keyPath = ( path ) ? path + "." + key : key
				if ( matchFunc(keyPath) )
				{
					callback( keyPath, key, value );
				}
				
				if ( typeof(value) == "table" )
				{
					ScriptDebugIterateKeysRecursive( matchFunc, keyPath, value, visits, callback )
				}
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Documentation table
//-----------------------------------------------------------------------------

if ( developer() > 0 )
{
	Documentation <-
	{
		classes = {}
		functions = {}
		instances = {}
	}


	function RetrieveNativeSignature( nativeFunction )
	{
		if ( nativeFunction in NativeFunctionSignatures )
		{
			return NativeFunctionSignatures[nativeFunction]
		}
		return "<unnamed>"
	}
	
	function RegisterFunctionDocumentation( func, name, signature, description )
	{
		if ( description.len() )
		{
			local b = ( description[0] == '#' );
			if ( description[0] == '#' )
			{
				local colon = description.find( ":" );
				if ( colon == null )
				{
					colon = description.len();
				}
				local alias = description.slice( 1, colon );
				description = description.slice( colon + 1 );
				name = alias;
				signature = "#";
			}
		}
		Documentation.functions[name] <- [ signature, description ]
	}

	function Document( symbolOrTable, itemIfSymbol = null, descriptionIfSymbol = null )
	{
		if ( typeof( symbolOrTable ) == "table" )
		{
			foreach( symbol, itemDescription in symbolOrTable )
			{
				Assert( typeof(symbol) == "string" )
				
				Document( symbol, itemDescription[0], itemDescription[1] );
			}
		}
		else
		{
			printl( symbolOrTable + ":" + itemIfSymbol.tostring() + "/" + descriptionIfSymbol );
		}
	}
	
	function PrintHelp( string = "*", exact = false )
	{
		local matches = []
		
		if ( string == "*" || !exact )
		{
			foreach( name, documentation in Documentation.functions )
			{
				if ( string != "*" && name.tolower().find( string.tolower() ) == null )
				{
					continue;
				}
				
				matches.append( name ); 
			}
		} 
		else if ( exact )
		{
			if ( string in Documentation.functions )
				matches.append( string )
		}
		
		if ( matches.len() == 0 )
		{
			printl( "Symbol " + string + " not found" );
			return;
		}
		
		matches.sort();
		
		foreach( name in matches )
		{
			local result = name;
			local documentation = Documentation.functions[name];
			
			printl( "Function:    " + name );
			local signature;
			if ( documentation[0] != "#" )
			{
				signature = documentation[0];
			}
			else
			{
				signature = GetFunctionSignature( this[name], name );
			}
			
			printl( "Signature:   " + signature );
			if ( documentation[1].len() )
				printl( "Description: " + documentation[1] );
			print( "\n" ); 
		}
	}
}
else
{
	function RetrieveNativeSignature( nativeFunction ) { return "<unnamed>"; }
	function RegisterFunctionDocumentation( func, name, signature, description ) {}
	function Document( symbolOrTable, itemIfSymbol = null, descriptionIfSymbol = null ) {}
	function PrintHelp( string = "*", exact = false ) {}
}

//-----------------------------------------------------------------------------
// VSquirrel support functions
//-----------------------------------------------------------------------------

function VSquirrel_OnCreateScope( name, outer )
{
	local result;
	if ( !(name in outer) )
	{
		result = outer[name] <- { __vname=name, __vrefs = 1 };
		result.setdelegate( outer );
	}
	else
	{
		result = outer[name];
		result.__vrefs += 1;
	}
	return result;
}

function VSquirrel_OnReleaseScope( scope )
{
	scope.__vrefs -= 1;
	if ( scope.__vrefs < 0 )
	{
		throw "Bad reference counting on scope " + scope.__vname;
	}
	else if ( scope.__vrefs == 0 )
	{
		delete scope.getdelegate()[scope.__vname];
		scope.__vname = null;
		scope.setdelegate( null );
	}
}


//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
class CCallChainer
{
	constructor( prefixString, scopeForThis = null )
	{
		prefix = prefixString;
		if ( scopeForThis != null )
			scope = scopeForThis;
		else
			scope = ::getroottable();
		chains = {};
		
		// Expose a bound global function to dispatch to this object
		scope[ "Dispatch" + prefixString ] <- Call.bindenv( this );
	}
	
	function PostScriptExecute() 
	{
		foreach( key, value in scope )
		{
			if ( typeof( value ) == "function" ) 
			{
				if ( key.find( prefix ) == 0 )
				{
					key = key.slice( prefix.len() );
					
					if ( !(key in chains) )
					{
						//::print( "Creating new call chain " + key + "\n");
						chains[key] <- [];
					}
					
					local chain = chains[key];
					
					if ( !chain.len() || chain.top() != value )
					{
						chain.push( value );
						//::print( "Added " + value + " to call chain " + key + "\n" );
					}
				}
			}
		}
	}
	
	function Call( event, ... )
	{
		if ( event in chains )
		{
			local chain = chains[event];
			if ( chain.len() )
			{
				local i;
				local args = [];
				if ( vargv.len() > 0 )
				{
					args.push( scope );
					for ( i = 0; i < vargv.len(); i++ )
					{
						args.push( vargv[i] );
					}
				}
				for ( i = chain.len() - 1; i >= 0; i -= 1 )
				{
					local func = chain[i];
					local result;
					if ( !args.len() )
					{
						result = func();
					}
					else
					{
						result = func.acall( args ); 
					}
					if ( result != null && !result )
						return false;
				}
			}
		}
		
		return true;
	}
	
	scope = null;
	prefix = null;
	chains = null;
};


//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
class CSimpleCallChainer
{
	constructor( prefixString, scopeForThis = null, exactNameMatch = false )
	{
		prefix = prefixString;
		if ( scopeForThis != null )
			scope = scopeForThis;
		else
			scope = ::getroottable();
		chain = [];
		
		// Expose a bound global function to dispatch to this object
		scope[ "Dispatch" + prefixString ] <- Call.bindenv( this );
		
		exactMatch = exactNameMatch
	}
	
	function PostScriptExecute() 
	{
		foreach( key, value in scope )
		{
			if ( typeof( value ) == "function" ) 
			{
				local foundMatch = false;
				if ( exactMatch )
				{
					foundMatch = ( prefix == key );
				}
				else
				{
					foundMatch = ( key.find( prefix ) == 0 )
				}
						
				if ( foundMatch )
				{
					if ( !exactMatch )
						key = key.slice( prefix.len() );
					
					if ( !(chain) )
					{
						//::print( "Creating new call simple chain\n");
						chain <- [];
					}
					
					if ( !chain.len() || chain != value )
					{
						chain.push( value );
						//::print( "Added " + value + " to call chain.\n" );
					}
				}
			}
		}
	}
	
	function Call( ... )
	{
		if ( chain.len() )
		{
			local i;
			local args = [];
			if ( vargv.len() > 0 )
			{
				args.push( scope );
				for ( i = 0; i < vargv.len(); i++ )
				{
					args.push( vargv[i] );
				}
			}
			for ( i = chain.len() - 1; i >= 0; i -= 1 )
			{
				local func = chain[i];
				local result;
				if ( !args.len() )
				{
					result = func.pcall( scope );
				}
				else
				{
					result = func.pacall( scope, args ); 
				}
				if ( result != null && !result )
					return false;
			}
		}
		
		return true;
	}
	
	exactMatch = false
	scope = null;
	prefix = null;
	chain = null;
};

//-----------------------------------------------------------------------------
// Late binding: allows a table to refer to parts of itself, it's children,
// it's owner, and then have the references fixed up after it's fully parsed
//
// Usage:
//    lateBinder <- LateBinder();
//    lateBinder.Begin( this );
//    
//    Test1 <-
//    {   
// 	   Foo=1
//    }   
//    
//    Test2 <-
//    {   
// 	   FooFoo = "I'm foo foo"
// 	   BarBar="@Test1.Foo"
// 	   SubTable = { boo=[bah, "@Test2.FooFoo", "@Test1.Foo"], booboo2={one=bah, two="@Test2.FooFoo", three="@Test1.Foo"} }
// 	   booboo=[bah, "@Test2.FooFoo", "@Test1.Foo"]
// 	   booboo2={one=bah, two="@Test2.FooFoo", three="@Test1.Foo"}
// 	   bah=wha
//    }   
//    
//    lateBinder.End();
//    delete lateBinder;
//
// When End() is called, all of the unresolved symbols in the tables and arrays will be resolved,
// any left unresolved will become a string prepended with '~', which later code can deal with
//-----------------------------------------------------------------------------

class LateBinder
{
	// public:
	function Begin( target, log = false )
	{
		m_log = log;
		
		HookRootMetamethod( "_get", function( key ) { return "^" + key; } );
		HookRootMetamethod( "_newslot", function( key, value ) { if ( typeof value == "table" ) { m_fixupSet.push( [ key, value ] ); this.rawset( key, value ); };  }.bindenv(this) );
		m_targetTable = target;
		
		Log( "Begin late bind on table " + m_targetTable );
	}
	
	function End()
	{
		UnhookRootMetamethod( "_get" );
		UnhookRootMetamethod( "_newslot" );

		Log( "End late bind on table " + m_targetTable );
		
		foreach( subTablePair in m_fixupSet )
		{
			EstablishDelegation( m_targetTable, subTablePair[1] );
		}

		Log( "Begin resolution... " )
		m_logIndent++;
		
		local found = true;
		
		while ( found )
		{
			foreach( subTablePair in m_fixupSet )
			{
				Log( subTablePair[0] + " = " );
				Log( "{" );
				if ( !Resolve( subTablePair[1], subTablePair[1], false ) )
				{
					found = false;
				}
				Log( "}" );
			}
		}
			
		m_logIndent--;
		
		foreach( subTablePair in m_fixupSet )
		{
			RemoveDelegation( subTablePair[1] );
		}
		
		Log( "...end resolution" );
	}
		
	// private:
	function HookRootMetamethod( name, value )
	{
		local saved = null;
		local roottable = getroottable();
		if ( name in roottable )
		{
			saved = roottable[name];
		}
		roottable[name] <- value;
		roottable["__saved" + name] <- saved;
	}

	function UnhookRootMetamethod( name )
	{
		local saveSlot = "__saved" + name;
		local roottable = getroottable();
		local saved = roottable[saveSlot];
		if ( saved != null )
		{
			roottable[name] = saved;
		}
		else
		{
			delete roottable[name];
		}
		delete roottable[saveSlot];
	}

	function EstablishDelegation( parentTable, childTable )
	{
		childTable.setdelegate( parentTable );
		
		foreach( key, value in childTable )
		{
			local type = typeof value;
			if ( type == "table" )
			{
				EstablishDelegation( childTable, value );
			}
		}
	}
	
	function RemoveDelegation( childTable )
	{
		childTable.setdelegate( null );
		
		foreach( key, value in childTable )
		{
			local type = typeof value;
			if ( type == "table" )
			{
				RemoveDelegation( value );
			}
		}
	}

	function Resolve( lookupTable, subTableOrArray, throwException = false )
	{
		m_logIndent++;
		local found = false;
	
		foreach( key, value in subTableOrArray )
		{
			local type = typeof value;
			if ( type == "string" )
			{
				if ( value.len() )
				{
					local unresolvedId = null;
					local controlChar = value[0]
					if ( controlChar == '^' )
					{
						found = true;
						value = value.slice( 1 );
						if ( value in lookupTable )
						{
							subTableOrArray[key] = lookupTable[value];
							Log( key + " = " + lookupTable[value] + " <-- " + value );
						}
						else
						{
							subTableOrArray[key] = "~" + value;
							unresolvedId = value;
							Log( key + " = \"" + "~" + value + "\" (unresolved)" );
						}
					}
					else if ( controlChar == '@' )
					{
						found = true;
						local identifiers = [];
						local iLast = 1;
						local iNext;
						while ( ( iNext = value.find( ".", iLast ) ) != null )
						{
							identifiers.push( value.slice( iLast, iNext ) );
							iLast = iNext + 1;
						}
						identifiers.push( value.slice( iLast ) );
						
						local depthSuccess = 0;
						local result = lookupTable;
						foreach( identifier in identifiers )
						{
							if ( identifier in result )
							{
								depthSuccess++;
								result = result[identifier];
							}
							else
							{
								break;
							}
						}
						if ( depthSuccess == identifiers.len() )
						{
							subTableOrArray[key] = result;
							Log( key + " = " + result + " <-- " + value );
						}
						else
						{
							subTableOrArray[key] = "~" + value.slice( 1 );
							unresolvedId = value;
							Log( key + " = \"" + "~" + value + "\" (unresolved)" );
						}
					}
					
					if ( unresolvedId != null )
					{
						if ( throwException )
						{
							local exception = "Unresolved symbol: " + bind + " in ";
							foreach ( entry in m_bindNamesStack )
							{
								exception += entry;
								exception += "."
							}
							exception += unresolvedId;
							
							throw exception; 
						}
					}
				}
			}
		}

		foreach( key, value in subTableOrArray )
		{
			local type = typeof value;
			local isTable = ( type == "table" );
			local isArray = ( type == "array" )
			if ( isTable || isArray )
			{
				Log( key + " =" );
				Log( isTable ? "{" : "[" );
				
				m_bindNamesStack.push( key );
				if ( Resolve( ( isTable ) ? value : lookupTable, value, throwException ) )
				{
					found = true;
				}
				m_bindNamesStack.pop();
				
				Log( isTable ? "}" : "]" );
			}
		}
		m_logIndent--;
		return found;
	}
	
	function Log( string )
	{
		if ( m_log )
		{
			for ( local i = 0; i < m_logIndent; i++ )
			{
				print( "  " );
			}
			
			printl( string );
		}
	}

	m_targetTable = null;
	m_fixupSet = [];
	m_bindNamesStack = [];
	m_log = false;
	m_logIndent = 0;
}

// support function to assemble help strings for script calls - call once all your stuff is in the VM
::_PublishedHelp <- {}
function AddToScriptHelp( scopeTable )
{
	foreach (idx, val in scopeTable )
	{
		if (typeof(val) == "function")
		{
			local helpstr = "scripthelp_" + idx
			if ( ( helpstr in scopeTable ) && ( ! (helpstr in ::_PublishedHelp) ) )
			{
//				RegisterFunctionDocumentation( val, idx, "#", scopeTable[helpstr] )
				RegisterFunctionDocumentation( val, idx, GetFunctionSignature( val, idx ), scopeTable[helpstr] )
				::_PublishedHelp[helpstr] <- true
				printl("Registered " + helpstr + " for " + val.tostring)
			}
		}
	}
}

////////////////////////////////////////////////////////////////////

// An spawner on the server is getting ready to
// prespawn an entity. It calls this function, sending us
// the entity that it's preparing to spawn. 
//=========================================================

function __ExecutePreSpawn( entity ) 
{
	__EntityMakerResult <- {}
	if ( "PreSpawnInstance" in this )
	{
		local overrides = PreSpawnInstance( entity.GetClassname(), entity.GetName() );
		local type = typeof( overrides );
		if ( type == "table" )
		{
			foreach( key, value in overrides )
			{
				switch ( typeof( value ) )
				{
				case "string":
					{
						entity.__KeyValueFromString( key, value );
						break;
					}
				case "integer":
				case "float":
				case "bool":
					{
						entity.__KeyValueFromFloat( key, value.tofloat() );
						break;
					}
					
				case "Vector":
					{
						entity.__KeyValueFromVector( key, value );
						break
					}
					
				default:
					{
						printl( "Cannot use " + typeof( value ) + " as a key" );
					}
				}
			}
		}
		
		if ( type == "bool" || type == "integer" )
		{
			return overrides;
		}
	}
};

function __FinishSpawn()
{
	__EntityMakerResult <- null;
}

///////////////////////////////////////////////////////////////

/*
	see copyright notice in sqrdbg.h
*/

local currentscope;
if ( ::getroottable().getdelegate() )
{
	currentscope = ::getroottable();
	::setroottable( ::getroottable().getdelegate() );
}
try {
	
local objs_reg = { maxid=0 ,refs={} }

complex_types <- {
	["table"] = null,
	["array"] = null,
	["class"] = null,
	["instance"] = null,
	["weakref"] = null,
}

function build_refs(t)
{
	if(t == ::getroottable())
		return;
	local otype = ::type(t);
	if(otype in complex_types)
	{
		if(!(t in objs_reg.refs)) {
			objs_reg.refs[t] <- objs_reg.maxid++;
		
		    iterateobject(t,function(o,i,val)
		    {
			    build_refs(val);
			    build_refs(i);
		    })
		}
				
		if ( otype == "table" && t.getdelegate() && t.getdelegate() != ::getroottable() )
		{
			build_refs( t.getdelegate() )
		}
	}
}

function getvalue(v)
{
	switch(::type(v))
	{
		case "table":
		case "array":
		case "class":
		case "instance":
			return objs_reg.refs[v].tostring();
		case "integer":
		case "float":
		    return v;
		case "bool":
		    return v.tostring();
		case "string":
			return v;
		case "null":
		    return "null";
		default:
			
			return pack_type(::type(v));
	}
}

local packed_types={
	["null"]="n",
	["string"]="s",
	["integer"]="i",
	["float"]="f",
	["userdata"]="u",
	["function"]="fn",
	["table"]="t",
	["array"]="a",
	["generator"]="g",
	["thread"]="h",
	["instance"]="x", 
	["class"]="y",  
	["bool"]="b",
	["weakref"]="w"  
}

function pack_type(type)
{
	if(type in packed_types)return packed_types[type]
	return type
} 

function iterateobject(obj,func)
{
	local ty = ::type(obj);
	if(ty == "instance") {
		try { //TRY TO USE _nexti
		    foreach(idx,val in obj)
		    {
				func(obj,idx,val);
		    }
		}
		catch(e) {
		   foreach(idx,val in obj.getclass())
		   {
			func(obj,idx,obj[idx]);
		   }
		}
	}
	else if(ty == "weakref") {
		func(obj,"@ref",obj.ref());
	}
	else {
		foreach(idx,val in obj)
		{
		    func(obj,idx,val);
		}
	}
			
}

function build_tree()
{
	foreach(i,o in objs_reg.refs)
	{
		beginelement("o");
		attribute("type",(i==::getroottable()?"r":pack_type(::type(i))));
		local _typeof = typeof i;
		if(_typeof != ::type(i)) {
			attribute("typeof",_typeof);
		}
		attribute("ref",o.tostring());
		if(i != ::getroottable()){
			if ( ::type(i) == "table" && i.getdelegate() && i.getdelegate() != ::getroottable() )
			{
				beginelement("e");
					emitvalue("kt","kv","[parent/delegate]");
					emitvalue("vt","v",i.getdelegate());
				endelement("e");	
			}

			iterateobject(i,function (obj,idx,val) {
				if(::type(val) == "function")
					return;
					
				if ( ::type(idx) == "string" && idx.find( "__" ) == 0 )
					return;

				beginelement("e");	
					emitvalue("kt","kv",idx);
					emitvalue("vt","v",obj[idx]);
				endelement("e");	

			})
		}
		endelement("o");
	}
}

function evaluate_watch(locals,id,expression)
{
	local func_src="return function ("
	local params=[];
	
	params.append(locals["this"])
	local first=1;
	foreach(i,v in locals){
		if(i!="this" && i[0] != '@'){ //foreach iterators start with @
			if(!first){
				func_src=func_src+","
				
			}
			first=null
			params.append(v)
			func_src=func_src+i
		}
	}
	func_src=func_src+"){\n"
	func_src=func_src+"return ("+expression+")\n}"
	
	try {
		local func=::compilestring(func_src);
		return {status="ok" , val=func().acall(params)};
	}
	catch(e)
	{
		
		return {status="error"}
	}
}

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
function emitvalue(type_attrib,value_attrib,val)
{
	attribute(type_attrib,pack_type(::type(val)));
	attribute(value_attrib,getvalue(val).tostring());
}

local stack=[]
local level=3;
local si;

	//ENUMERATE THE STACK WATCHES
	while(si=::getstackinfos(level))
	{
		stack.append(si);
		level++;
	}

	//EVALUATE ALL WATCHES
	objs_reg.refs[::getroottable()] <- objs_reg.maxid++;
	foreach(i,val in stack)
	{
		if(val.src!="NATIVE") {
			if("watches" in this) {
				val.watches <- {}
				foreach(i,watch in watches)
				{
					if(val.src!="NATIVE"){
						val.watches[i] <- evaluate_watch(val.locals,i,watch);
						if(val.watches[i].status!="error")
							build_refs(val.watches[i].val);
					}
					else{
						val.watches[i] <- {status="error"}
					}
					val.watches[i].exp <- watch;
				}
				
			}
		}
		foreach(i,l in val.locals)
			build_refs(l);
	}


	beginelement("objs");
	build_tree();
	endelement("objs");

	beginelement("calls");

	foreach(i,val in stack)
	{

		beginelement("call");
		attribute("fnc",val.func);
		attribute("src",val.src);
		attribute("line",val.line.tostring());
		foreach(i,v in val.locals)
		{
			beginelement("l");
				attribute("name",getvalue(i).tostring());
				emitvalue("type","val",v);
			endelement("l");
		}
		if("watches" in val) {
			foreach(i,v in val.watches)
			{
				beginelement("w");
					attribute("id",i.tostring());
					attribute("exp",v.exp);
					attribute("status",v.status);
					if(v.status!="error") {
						emitvalue("type","val",v.val);
					}
				endelement("w");
			}
		}
		endelement("call");
		 
	}
	endelement("calls");


	objs_reg = null;
	stack = null;
	
	if("collectgarbage" in ::getroottable()) ::collectgarbage();
}catch(e)
{
	::print("ERROR"+e+"\n");
}

if ( currentscope )
{
	::setroottable( currentscope );
}

/////////////////////////

//========== Copyright © 2008, Valve Corporation, All rights reserved. ========
//
// Purpose:
//
//=============================================================================

function UniqueString( string = "" )
{
	return DoUniqueString( string.tostring() );
}

function EntFire( target, action, value = null, delay = 0.0, activator = null )
{
	if ( !value )
	{
		value = "";
	}
	
	local caller = null;
	if ( "self" in this )
	{
		caller = self;
		if ( !activator )
		{
			activator = self;
		}
	}
	
	DoEntFire( target.tostring(), action.tostring(), value.tostring(), delay, activator, caller ); 
}

function __ReplaceClosures( script, scope )
{
	if ( !scope )
	{
		scope = getroottable();
	}
	
	local tempParent = { getroottable = function() { return null; } };
	local temp = { runscript = script };
	temp.setdelegate( tempParent );
	
	temp.runscript()
	foreach( key,val in temp )
	{
		if ( typeof(val) == "function" && key != "runscript" )
		{
			printl( "   Replacing " + key );
			scope[key] <- val;
		}
	}
}

__OutputsPattern <- regexp("^On.*Output$");

function ConnectOutputs( table )
{
	const nCharsToStrip = 6;
	foreach( key, val in table )
	{
		if ( typeof( val ) == "function" && __OutputsPattern.match( key ) )
		{
			//printl(key.slice( 0, nCharsToStrip ) );
			table.self.ConnectOutput( key.slice( 0, key.len() - nCharsToStrip ), key );
		}
	}
}

function IncludeScript( name, scope = null )
{
	if ( scope == null )
	{
		scope = this;
	}
	return ::DoIncludeScript( name, scope );
}

//---------------------------------------------------------
// Text dump this scope's contents to the console.
//---------------------------------------------------------
function __DumpScope( depth, table )
{
	local indent=function( count )
	{
		local i;
		for( i = 0 ; i < count ; i++ )
		{
			print("   ");
		}
	}
	
    foreach(key, value in table)
    {
		indent(depth);
		print( key );
        switch (type(value))
        {
            case "table":
				print("(TABLE)\n");
				indent(depth);
                print("{\n");
                __DumpScope( depth + 1, value);
				indent(depth);
                print("}");
                break;
            case "array":
				print("(ARRAY)\n");
				indent(depth);
                print("[\n")
                __DumpScope( depth + 1, value);
				indent(depth);
                print("]");
                break;
            case "string":
                print(" = \"");
                print(value);
                print("\"");
                break;
            default:
                print(" = ");
                print(value);
                break;
        }
        print("\n");  
	}
}

//---------------------------------------------------------
function ClearGameEventCallbacks()
{
	::GameEventCallbacks <- {};
	::ScriptEventCallbacks <- {};
}

//---------------------------------------------------------
// Collect functions of the form OnGameEventXXX and store them in a table.
//---------------------------------------------------------
function __CollectEventCallbacks( scope, prefix, globalTableName, regFunc )
{
	if ( !(typeof( scope ) == "table" ) )
	{
		print( "__CollectEventCallbacks[" + prefix +"]: NOT TABLE! : " + typeof ( scope ) + "\n" );
		return;
	}

	if ( !(globalTableName in getroottable())  )
	{
		getroottable()[globalTableName] <- {};
	}
	local useTable = getroottable()[globalTableName] 
	foreach( key,value in scope )
	{
		if ( typeof( value ) == "function" )
		{
			if ( typeof( key ) == "string" && key.find( prefix, 0 ) == 0 )
			{
				local eventName = key.slice( prefix.len() ); 
				if ( eventName.len() > 0 )
				{
					// First time we've seen this event: Make an array for callbacks and
					// tell the game engine's listener we want to be notified.
					if ( !(eventName in useTable) )
					{
						useTable[eventName] <- [];
						if (regFunc)
							regFunc( eventName );
					}
					// Don't add duplicates. TODO: Perf on this...
					else if ( useTable[eventName].find( scope ) != null )
					{
						continue;
					}
					useTable[eventName].append( scope.weakref() );
				}
			}
		}
	}	
}

function __CollectGameEventCallbacks( scope )
{
	__CollectEventCallbacks( scope, "OnGameEvent_", "GameEventCallbacks", ::RegisterScriptGameEventListener )
	__CollectEventCallbacks( scope, "OnScriptEvent_", "ScriptEventCallbacks", null )
}

//---------------------------------------------------------
// Call all functions in the callback array for the given game event.
//---------------------------------------------------------
function __RunEventCallbacks( event, params, prefix, globalTableName, bWarnIfMissing )
{
	local useTable = getroottable()[globalTableName] 
	if ( !(event in useTable) )
	{
		if (bWarnIfMissing)
		    print( "__RunEventCallbacks[" + prefix + "]: Invalid 'event' name: " + event + ". No listeners registered for that event.\n" );
		return;
	}

	for ( local idx = useTable[event].len()-1; idx >= 0; --idx )
	{
		local funcName = prefix + event;
		if ( useTable[event][idx] == null )
		{
			//TODO: Not a great way to deal with cleanup...
			useTable[event].remove(idx);
		}
		else
		{
			//PERF TODO: This is a hash lookup for a function we know exists...
			// should be caching it off in CollectGameEventCallbacks.
			useTable[event][idx][funcName]( params );
		}
	}
}

function __RunGameEventCallbacks( event, params )
{
	__RunEventCallbacks( event, params, "OnGameEvent_", "GameEventCallbacks", true )
}

// kinda want to rename this "SendScriptEvent" - since we just send it to script
function FireScriptEvent( event, params )
{
	__RunEventCallbacks( event, params, "OnScriptEvent_", "ScriptEventCallbacks", false )
}


//-----------------------------------------------------------------------------
// Debug watches & trace
//-----------------------------------------------------------------------------

const ScriptDebugFirstLine 				= 6
const ScriptDebugTextLines 				= 20
const ScriptDebugTextTime 				= 10.0
const ScriptDebugWatchFistLine 			= 26
const NDEBUG_PERSIST_TILL_NEXT_SERVER 	= 0.01023
ScriptDebugDefaultWatchColor <- [ 0, 192, 0 ]

//-----------------------------------------------------------------------------

// Text is stored as an array of [ time, string, [ r, g, b ] ]
ScriptDebugText 		<- []
ScriptDebugTextIndent 	<- 0
ScriptDebugTextFilters	<- {}

ScriptDebugInDebugDraw <- false

ScriptDebugDrawWatchesEnabled <- true
ScriptDebugDrawTextEnabled <- true

// A watch is [ { key, function, color = [ r, g, b ], lastValue, lastChangeText } ]
ScriptDebugWatches 		<- []

ScriptDebugTraces 		<- {}
ScriptDebugTraceAllOn	<- false

//-----------------------------------------------------------------------------

function ScriptDebugDraw()
{
	ScriptDebugInDebugDraw = true

	if ( ScriptDebugDrawTextEnabled || ScriptDebugDrawWatchesEnabled )
	{
		ScriptDebugTextDraw( ScriptDebugFirstLine )
	}

	if ( ScriptDebugDrawWatchesEnabled )
	{
		ScriptDebugDrawWatches( ScriptDebugWatchFistLine )
	}

	ScriptDebugInDebugDraw = false
}

//-----------------------------------------------------------------------------

function ScriptDebugDrawWatches( line )
{
	local nWatches = ScriptDebugWatches.len()
	local curWatchKey
	local curWatchColor
	local curWatchValue
	local curWatchPath
	local curWatchString
	local ignored
	local bRedoExpand
	local changed
	
	for ( local i = 0; i < ScriptDebugWatches.len(); i++ )
	{
		curWatchKey = ScriptDebugWatches[i].key;
		curWatchColor = ScriptDebugWatches[i].color;
		
		if ( typeof( curWatchKey ) == "function" )
		{
			curWatchString = "" 
		}
		else
		{
			curWatchString = curWatchKey + ": "
		}
		
		try
		{
			local watchResult = ScriptDebugWatches[i].func.pcall(::getroottable())
			changed = false;
			if ( watchResult != null )
			{
				if ( watchResult != ScriptDebugWatches[i].lastValue )
				{
					if ( ScriptDebugWatches[i].lastValue != null )
					{
						ScriptDebugWatches[i].lastChangeText = " (was " + ScriptDebugWatches[i].lastValue + " @ " + Time() + ")"
						changed = true
					}
					ScriptDebugWatches[i].lastValue = watchResult
				}
				
				curWatchString = curWatchString + watchResult.tostring() + ScriptDebugWatches[i].lastChangeText
				if ( changed) 
				{
					ScriptDebugTextPrint( curWatchString, [ 0, 255, 0 ], true );
				}
			}
			else
			{
				curWatchString = curWatchString + "<<null>>"
			}
		}
		catch ( error )
		{
			curWatchString = curWatchString + "Watch failed - " + error.tostring()
		}
		
		DebugDrawScreenTextLine( 0.5, 0.0, line++, curWatchString, curWatchColor[0], curWatchColor[1], curWatchColor[2], 255, NDEBUG_PERSIST_TILL_NEXT_SERVER );
	}
	
	return line
}

//-----------------------------------------------------------------------------

function ScriptDebugAddWatch( watch )
{
	local watchType = typeof(watch)
	local i

	switch ( watchType )
	{
	case "function":
		{
			watch = { key = watch, func = watch, color = ScriptDebugDefaultWatchColor, lastValue = null, lastChangeText = "" }
			break;
		}
		
	case "string":
		{
			local closure
			try
			{
				closure = compilestring( "return " + watch, "" )
			}
			catch ( error )
			{
				ScriptDebugTextPrint( "Failed to add watch \"" + watch + "\": " + error.tostring() )
				return
			}
			watch = { key = watch, func = closure, color = ScriptDebugDefaultWatchColor, lastValue = null, lastChangeText = "" }
			break;
		}
	default:
		throw "Illegal type passed to ScriptDebugAddWatch: " + watchType
	}

	local function FindExisting( watch )
	{
		foreach( key, val in ScriptDebugWatches )
		{
			if ( val.key == watch.key )
			{
				return key
			}
		}
		return -1
	}
	
	local iExisting
	if ( ( iExisting = FindExisting( watch ) ) == -1 )
	{
		ScriptDebugWatches.append( watch )
	}
	else
	{
		// just update the color
		ScriptDebugWatches[iExisting].color = watch.color
	}
}

//-----------------------------------------------------------------------------

function ScriptDebugAddWatches( watchArray )
{
	if ( typeof( watchArray ) == "array" )
	{
		for ( local i = 0; i < watchArray.len(); i++ )
		{
			ScriptDebugAddWatch( watchArray[i] );
		}
	}
	else
	{
		throw "ScriptDebugAddWatches() expected an array!"
	}
}

//-----------------------------------------------------------------------------

function ScriptDebugRemoveWatch( watch )
{
	for ( local i = ScriptDebugWatches.len() - 1; i >= 0; --i )
	{
		if ( ScriptDebugWatches[i].key == watch )
		{
			ScriptDebugWatches.remove( i );
		}
	}
}

//-----------------------------------------------------------------------------

function ScriptDebugRemoveWatches( watchArray )
{
	if ( typeof( watchArray ) == "array" )
	{
		for ( local i = 0; i < watchArray.len(); i++ )
		{
			ScriptDebugRemoveWatch( watchArray[i] );
		}
	}
	else
	{
		throw "ScriptDebugAddWatches() expected an array!"
	}
}

//-----------------------------------------------------------------------------

function ScriptDebugAddWatchPattern( name )
{
	if ( name == "" )
	{
		Msg( "Cannot find an empty string" )
		return;
	}
	
	local function OnKey( keyPath, key, value )
	{
		if ( keyPath.find( "Documentation." ) != 0 )
		{
			ScriptDebugAddWatch( keyPath );
		}
	}
	
	ScriptDebugIterateKeys( name, OnKey );
}

//-----------------------------------------------------------------------------

function ScriptDebugRemoveWatchPattern( name )
{
	if ( name == "" )
	{
		Msg( "Cannot find an empty string" )
		return;
	}
	
	local function OnKey( keyPath, key, value )
	{
		ScriptDebugRemoveWatch( keyPath ); 
	}
	
	ScriptDebugIterateKeys( name, OnKey );
}

//-----------------------------------------------------------------------------

function ScriptDebugClearWatches()
{
	ScriptDebugWatches.clear()
}

//-----------------------------------------------------------------------------

function ScriptDebugTraceAll( bValue = true )
{
	ScriptDebugTraceAllOn = bValue
}

function ScriptDebugAddTrace( traceTarget )
{
	local type = typeof( traceTarget )
	if (  type == "string" || type == "table" || type == "instance" )
	{
		ScriptDebugTraces[traceTarget] <- true
	}
}

function ScriptDebugRemoveTrace( traceTarget )
{
	if ( traceTarget in ScriptDebugTraces )
	{
		delete ScriptDebugTraces[traceTarget]
	}
}

function ScriptDebugClearTraces()
{
	ScriptDebugTraceAllOn = false
	ScriptDebugTraces.clear()
}

function ScriptDebugTextTrace( text, color = [ 255, 255, 255 ] )
{
	local bPrint = ScriptDebugTraceAllOn

	if ( !bPrint && ScriptDebugTraces.len() )
	{
		local stackinfo = getstackinfos( 2 )
		if ( stackinfo != null )
		{
			if ( ( stackinfo.func in ScriptDebugTraces ) ||
				 ( stackinfo.src in ScriptDebugTraces ) ||
				 ( stackinfo.locals["this"] in ScriptDebugTraces ) )
			{
				bPrint = true
			}
		}
	}
	
	if ( bPrint )
	{
		ScriptDebugTextPrint( text, color )
	}
}

//-----------------------------------------------------------------------------

function ScriptDebugTextPrint( text, color = [ 255, 255, 255 ], isWatch = false )
{
	foreach( key, val in ScriptDebugTextFilters )
	{
		if ( text.find( key ) != null )
		{
			return;
		}
	}

	local timeString = format( "(%0.2f) ", Time() ) 

	if ( ScriptDebugDrawTextEnabled || ( isWatch && ScriptDebugDrawWatchesEnabled ) )
	{
		local indentString = "";
		local i = ScriptDebugTextIndent
		while ( i-- )
		{
			indentString = indentString + "   "
		}
		
		// Screen overlay
		local debugString = timeString + indentString + text.tostring()
		ScriptDebugText.append( [ Time(), debugString.tostring(), color ] )
		if ( ScriptDebugText.len() > ScriptDebugTextLines )
		{
			ScriptDebugText.remove( 0 )
		}
	}
	
	// Console
	printl( text + " " + timeString );
}

//-----------------------------------------------------------------------------

function ScriptDebugTextDraw( line )
{
	local i
	local alpha
	local curtime = Time()
	local age
	for ( i = 0; i < ScriptDebugText.len(); i++ )
	{
		age = curtime - ScriptDebugText[i][0]
		if ( age < -1.0 )
		{
			// Started a new server
			ScriptDebugText.clear()
			break;
		}

		if ( age < ScriptDebugTextTime )
		{
			if ( age >= ScriptDebugTextTime - 1.0 )
			{
				alpha = ( 255.0 * ( ScriptDebugTextTime - age ) ).tointeger()
				Assert( alpha >= 0 )
			}
			else
			{
				alpha = 255
			}
			
			DebugDrawScreenTextLine( 0.5, 0.0, line++, ScriptDebugText[i][1], ScriptDebugText[i][2][0], ScriptDebugText[i][2][1], ScriptDebugText[i][2][2], alpha, NDEBUG_PERSIST_TILL_NEXT_SERVER );
		}
	}
	
	return line + ScriptDebugTextLines - i;
}

//-----------------------------------------------------------------------------

function ScriptDebugAddTextFilter( filter )
{
	ScriptDebugTextFilters[filter] <- true
}

//-----------------------------------------------------------------------------

function ScriptDebugRemoveTextFilter( filter )
{
	if ( filter in ScriptDebugTextFilters )
	{
		delete ScriptDebugTextFilters[filter]
	}
}

//-----------------------------------------------------------------------------

function ScriptDebugHook( type, file, line, funcname )
{
	if ( ScriptDebugInDebugDraw )
	{
		return
	}

	if ( ( type == 'c' || type == 'r' ) && file != "unnamed" && file != "" && file != "game_debug.nut" && funcname != null )
	{
		local functionString = funcname + "() [ " + file + "(" + line + ") ]"

		foreach( key, val in ScriptDebugTextFilters )
		{
			if ( file.find( key ) != null || functionString.find( key ) != null )
			{
				return;
			}
		}
		
		if ( type == 'c' )
		{
			local indentString = "";
			local i = ScriptDebugTextIndent
			while ( i-- )
			{
				indentString = indentString + "   "
			}
			
			// Screen overlay
			local timeString = format( "(%0.2f) ", Time() ) 
			local debugString = timeString + indentString + functionString
			ScriptDebugTextPrint( functionString );
			ScriptDebugTextIndent++;
			
			// Console
			printl( "{" ); 
			print_indent++;
		}
		else
		{
			ScriptDebugTextIndent--;
			print_indent--;
			printl( "}" );
			
			if ( ScriptDebugTextIndent == 0 )
			{
				ScriptDebugExpandWatches()
			}
		}
	}
}

//-----------------------------------------------------------------------------

function __VScriptServerDebugHook( type, file, line, funcname )
{
	ScriptDebugHook( type, file, line, funcname ) // route to support debug script reloading during development 
}

function BeginScriptDebug()
{
	setdebughook( __VScriptServerDebugHook );
}

function EndScriptDebug()
{
	setdebughook( null );
}
