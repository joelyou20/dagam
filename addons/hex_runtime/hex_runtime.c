/* Minimal Godot 4.3+ C GDExtension. No Node, browser, networking or OS APIs are exposed. */
#include "gdextension_interface.h"
#include "vendor/quickjs.h"
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdio.h>
typedef union { uint64_t align; unsigned char bytes[24]; } Store;
typedef struct { JSRuntime *rt; JSContext *ctx; clock_t deadline; } Runtime;
static GDExtensionClassLibraryPtr library;
static Store class_name, parent_name;
static GDExtensionInterfaceClassdbConstructObject construct_object;
static GDExtensionInterfaceObjectSetInstance set_instance;
static GDExtensionInterfaceStringNameNewWithUtf8Chars name_new;
static GDExtensionInterfaceStringNewWithUtf8Chars string_new;
static GDExtensionInterfaceStringToUtf8Chars string_utf8;
static GDExtensionInterfaceClassdbRegisterExtensionClass2 register_class;
static GDExtensionInterfaceClassdbRegisterExtensionClassMethod register_method;
static GDExtensionInterfaceClassdbUnregisterExtensionClass unregister_class;
static GDExtensionVariantFromTypeConstructorFunc variant_from_string;
static GDExtensionTypeFromVariantConstructorFunc string_from_variant;
static GDExtensionPtrDestructor destroy_string, destroy_name;
static int interrupt(JSRuntime *rt, void *opaque) { (void)rt; Runtime *r=opaque; return clock()>r->deadline; }
static GDExtensionObjectPtr create(void *unused) {
 (void)unused; Runtime *r=calloc(1,sizeof(*r)); r->rt=JS_NewRuntime();
 JS_SetMemoryLimit(r->rt,128*1024*1024); JS_SetMaxStackSize(r->rt,2*1024*1024);
 JS_SetInterruptHandler(r->rt,interrupt,r); r->ctx=JS_NewContext(r->rt);
 GDExtensionObjectPtr obj=construct_object(&parent_name); set_instance(obj,&class_name,r); return obj;
}
static void release(void *unused, GDExtensionClassInstancePtr ptr) { (void)unused; Runtime *r=ptr; JS_FreeContext(r->ctx); JS_FreeRuntime(r->rt); free(r); }
static char *evaluate(Runtime *r, GDExtensionConstStringPtr input) {
 int64_t size=string_utf8(input,NULL,0); char *code=malloc(size+1); string_utf8(input,code,size); code[size]=0;
 r->deadline=clock()+CLOCKS_PER_SEC*12; JSValue value=JS_Eval(r->ctx,code,size,"hex",JS_EVAL_TYPE_GLOBAL); free(code);
 char *result;
 if(JS_IsException(value)) { JSValue error=JS_GetException(r->ctx); const char *message=JS_ToCString(r->ctx,error); JSValue stack=JS_GetPropertyStr(r->ctx,error,"stack"); const char *trace=JS_ToCString(r->ctx,stack); fprintf(stderr,"Hex runtime: %s\n%s\n",message?message:"error",trace?trace:"");
 JSValue out=JS_NewObject(r->ctx); JS_SetPropertyStr(r->ctx,out,"error",JS_NewString(r->ctx,message?message:"Engine exception")); JSValue json=JS_JSONStringify(r->ctx,out,JS_UNDEFINED,JS_UNDEFINED); const char *encoded=JS_ToCString(r->ctx,json); result=strdup(encoded?encoded:"{\"error\":\"Engine exception\"}"); JS_FreeCString(r->ctx,encoded); JS_FreeValue(r->ctx,json); JS_FreeValue(r->ctx,out); JS_FreeCString(r->ctx,message); JS_FreeCString(r->ctx,trace); JS_FreeValue(r->ctx,stack); JS_FreeValue(r->ctx,error);
 } else { const char *text=JS_ToCString(r->ctx,value); result=strdup(text?text:""); JS_FreeCString(r->ctx,text); }
 JS_FreeValue(r->ctx,value); return result;
}
static void call(void *unused,GDExtensionClassInstancePtr instance,const GDExtensionConstVariantPtr *args,GDExtensionInt count,GDExtensionVariantPtr ret,GDExtensionCallError *error) {
 (void)unused; error->error=GDEXTENSION_CALL_OK; Store input={0},output={0};
 if(count!=1){error->error=GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS;return;}
 string_from_variant(&input,(GDExtensionVariantPtr)args[0]); char *text=evaluate(instance,&input); string_new(&output,text); variant_from_string(ret,&output); destroy_string(&input); destroy_string(&output);free(text);
}
static void ptrcall(void *unused,GDExtensionClassInstancePtr instance,const GDExtensionConstTypePtr *args,GDExtensionTypePtr ret) { (void)unused;char *text=evaluate(instance,args[0]); string_new(ret,text);free(text); }
static void initialize(void *unused,GDExtensionInitializationLevel level) {
 (void)unused;if(level!=GDEXTENSION_INITIALIZATION_SCENE)return;
 name_new(&class_name,"HexRuntime");name_new(&parent_name,"RefCounted");
 GDExtensionClassCreationInfo2 info={0};info.is_exposed=1;info.create_instance_func=create;info.free_instance_func=release;register_class(library,&class_name,&parent_name,&info);
 Store method={0},arg={0},empty={0},hint={0}; name_new(&method,"evaluate");name_new(&arg,"source");name_new(&empty,"");string_new(&hint,"");
 GDExtensionPropertyInfo property={GDEXTENSION_VARIANT_TYPE_STRING,&arg,&empty,0,&hint,6};
 GDExtensionClassMethodArgumentMetadata metadata=GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
 GDExtensionClassMethodInfo m={0};m.arguments_metadata=&metadata;m.name=&method;m.call_func=call;m.ptrcall_func=ptrcall;m.method_flags=GDEXTENSION_METHOD_FLAG_NORMAL;m.has_return_value=1;m.return_value_info=&property;m.argument_count=1;m.arguments_info=&property;register_method(library,&class_name,&m);
 destroy_name(&method);destroy_name(&arg);destroy_name(&empty);destroy_string(&hint);
}
static void deinitialize(void *unused,GDExtensionInitializationLevel level) { (void)unused;if(level==GDEXTENSION_INITIALIZATION_SCENE){unregister_class(library,&class_name);destroy_name(&class_name);destroy_name(&parent_name);} }
#if defined(_WIN32)
__declspec(dllexport)
#else
__attribute__((visibility("default")))
#endif
GDExtensionBool hex_library_init(GDExtensionInterfaceGetProcAddress get,GDExtensionClassLibraryPtr lib,GDExtensionInitialization *init) {
 library=lib;
#define LOAD(name,type,symbol) name=(type)get(symbol)
 LOAD(construct_object,GDExtensionInterfaceClassdbConstructObject,"classdb_construct_object");LOAD(set_instance,GDExtensionInterfaceObjectSetInstance,"object_set_instance");LOAD(name_new,GDExtensionInterfaceStringNameNewWithUtf8Chars,"string_name_new_with_utf8_chars");LOAD(string_new,GDExtensionInterfaceStringNewWithUtf8Chars,"string_new_with_utf8_chars");LOAD(string_utf8,GDExtensionInterfaceStringToUtf8Chars,"string_to_utf8_chars");LOAD(register_class,GDExtensionInterfaceClassdbRegisterExtensionClass2,"classdb_register_extension_class2");LOAD(register_method,GDExtensionInterfaceClassdbRegisterExtensionClassMethod,"classdb_register_extension_class_method");LOAD(unregister_class,GDExtensionInterfaceClassdbUnregisterExtensionClass,"classdb_unregister_extension_class");
 variant_from_string=((GDExtensionInterfaceGetVariantFromTypeConstructor)get("get_variant_from_type_constructor"))(GDEXTENSION_VARIANT_TYPE_STRING);string_from_variant=((GDExtensionInterfaceGetVariantToTypeConstructor)get("get_variant_to_type_constructor"))(GDEXTENSION_VARIANT_TYPE_STRING);
 GDExtensionInterfaceVariantGetPtrDestructor destructor=(GDExtensionInterfaceVariantGetPtrDestructor)get("variant_get_ptr_destructor");destroy_string=destructor(GDEXTENSION_VARIANT_TYPE_STRING);destroy_name=destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME);
 init->minimum_initialization_level=GDEXTENSION_INITIALIZATION_SCENE;init->userdata=NULL;init->initialize=initialize;init->deinitialize=deinitialize;return 1;
}
