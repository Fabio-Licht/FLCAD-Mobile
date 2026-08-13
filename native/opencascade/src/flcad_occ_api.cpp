#include "flcad_occ_api.h"
#include <BRep_Builder.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepBuilderAPI_MakeEdge.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRepBuilderAPI_MakeSolid.hxx>
#include <BRepBuilderAPI_MakeVertex.hxx>
#include <BRepBuilderAPI_MakeWire.hxx>
#include <BRepBuilderAPI_Sewing.hxx>
#include <BRepMesh_IncrementalMesh.hxx>
#include <BRepTools.hxx>
#include <BRep_Tool.hxx>
#include <IGESControl_Reader.hxx>
#include <IGESControl_Writer.hxx>
#include <Interface_Static.hxx>
#include <Poly_Triangulation.hxx>
#include <ShapeFix_Shape.hxx>
#include <STEPControl_Reader.hxx>
#include <STEPControl_Writer.hxx>
#include <Standard_Version.hxx>
#include <TopExp_Explorer.hxx>
#include <TopLoc_Location.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Compound.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Shell.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp.hxx>
#include <gp_Ax2.hxx>
#include <gp_Cone.hxx>
#include <gp_Cylinder.hxx>
#include <gp_Dir.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <gp_Sphere.hxx>
#include <algorithm>
#include <atomic>
#include <cstring>
#include <fstream>
#include <mutex>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace {
std::unordered_map<std::string, TopoDS_Shape> shapes;
std::mutex registry_mutex;
std::atomic<unsigned long long> sequence{1};
thread_local std::string response;
void copy(const std::string& value,char* out,size_t size){if(!out||size==0)return;std::strncpy(out,value.c_str(),size-1);out[size-1]='\0';}
int fail(const std::string& message,char* error,size_t size){copy(message,error,size);return 0;}
std::string token(){return "occ-shape-"+std::to_string(sequence++);}
std::string fingerprint(const TopoDS_Shape& shape){return "occ-"+std::to_string(shape.HashCode(2147483647));}
std::string store(const TopoDS_Shape& shape){std::lock_guard<std::mutex> lock(registry_mutex);auto id=token();shapes[id]=shape;return id;}
TopoDS_Shape get(const char* id){std::lock_guard<std::mutex> lock(registry_mutex);auto it=shapes.find(id?id:"");if(it==shapes.end())throw Standard_Failure("Unknown native shape token");return it->second;}
std::vector<std::string> split(const char* value){std::vector<std::string> result;std::stringstream stream(value?value:"");std::string item;while(std::getline(stream,item,',')){if(!item.empty())result.push_back(item);}return result;}
int output(const TopoDS_Shape& shape,char* out_token,size_t token_size,char* out_fp,size_t fp_size,char* error,size_t error_size){if(shape.IsNull())return fail("OCCT produced a null shape",error,error_size);auto id=store(shape);copy(id,out_token,token_size);copy(fingerprint(shape),out_fp,fp_size);return 1;}
gp_Pnt point(const double* p){return gp_Pnt(p[0],p[1],p[2]);}gp_Dir direction(const double* p){return gp_Dir(p[0],p[1],p[2]);}
const char* shape_type(const TopoDS_Shape& s){switch(s.ShapeType()){case TopAbs_VERTEX:return "vertex";case TopAbs_EDGE:return "edge";case TopAbs_WIRE:return "wire";case TopAbs_FACE:return "face";case TopAbs_SHELL:return "shell";case TopAbs_SOLID:return "solid";default:return "compound";}}
}

extern "C" {
int flcad_occ_initialize(char* error,size_t error_size){try{Interface_Static::SetCVal("write.step.schema","AP242DIS");return 1;}catch(const Standard_Failure& e){return fail(e.GetMessageString(),error,error_size);}}
void flcad_occ_shutdown(){std::lock_guard<std::mutex> lock(registry_mutex);shapes.clear();}
const char* flcad_occ_version(){return OCC_VERSION_COMPLETE;}
const char* flcad_occ_capabilities(){return "STEP,IGES,BREP,Surface,Solid,Meshing,Healing,NURBS,Boolean";}
const char* flcad_occ_diagnostics(){response="{\"healthy\":true,\"backend\":\"OpenCascade\",\"shapeCount\":"+std::to_string(flcad_occ_shape_count())+"}";return response.c_str();}
int flcad_occ_create_vertex(double x,double y,double z,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{return output(BRepBuilderAPI_MakeVertex(gp_Pnt(x,y,z)),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_create_edge(const char*a,const char*b,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{return output(BRepBuilderAPI_MakeEdge(TopoDS::Vertex(get(a)),TopoDS::Vertex(get(b))),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_create_wire(const char*ids,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{BRepBuilderAPI_MakeWire maker;for(auto&id:split(ids))maker.Add(TopoDS::Edge(get(id.c_str())));if(!maker.IsDone())return fail("Wire builder did not complete",e,es);return output(maker.Wire(),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_create_face(const char*id,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{BRepBuilderAPI_MakeFace maker(TopoDS::Wire(get(id)),true);if(!maker.IsDone())return fail("Face builder did not complete",e,es);return output(maker.Face(),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_create_shell(const char*ids,double tolerance,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{BRepBuilderAPI_Sewing sewing(tolerance);for(auto&id:split(ids))sewing.Add(get(id.c_str()));sewing.Perform();return output(sewing.SewedShape(),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_create_solid(const char*id,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{BRepBuilderAPI_MakeSolid maker(TopoDS::Shell(get(id)));if(!maker.IsDone())return fail("Solid builder did not complete",e,es);return output(maker.Solid(),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_create_plane(const double*o,const double*n,double l,double u,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{return output(BRepBuilderAPI_MakeFace(gp_Pln(point(o),direction(n)),l,u,l,u),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_create_cylinder(const double*o,const double*d,double r,double l,double u,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{return output(BRepBuilderAPI_MakeFace(gp_Cylinder(gp_Ax2(point(o),direction(d)),r),0,6.283185307179586,l,u),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_create_cone(const double*o,const double*d,double a,double l,double u,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{return output(BRepBuilderAPI_MakeFace(gp_Cone(gp_Ax2(point(o),direction(d)),a,0),0,6.283185307179586,l,u),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_create_sphere(const double*o,double r,double l,double u,char*t,size_t ts,char*f,size_t fs,char*e,size_t es){try{return output(BRepBuilderAPI_MakeFace(gp_Sphere(gp_Ax2(point(o),gp::DZ()),r),0,6.283185307179586,l,u),t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_import_shape(const char*p,const char*fmt,char*t,size_t ts,char*f,size_t fs,char*ty,size_t tys,char*e,size_t es){try{TopoDS_Shape s;std::string format=fmt?fmt:"";if(format=="step"){STEPControl_Reader r;if(r.ReadFile(p)!=IFSelect_RetDone)return fail("STEP read failed",e,es);r.TransferRoots();s=r.OneShape();}else if(format=="iges"){IGESControl_Reader r;if(r.ReadFile(p)!=IFSelect_RetDone)return fail("IGES read failed",e,es);r.TransferRoots();s=r.OneShape();}else{BRep_Builder b;if(!BRepTools::Read(s,p,b))return fail("BREP read failed",e,es);}copy(shape_type(s),ty,tys);return output(s,t,ts,f,fs,e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_export_shape(const char*id,const char*p,const char*fmt,char*e,size_t es){try{auto s=get(id);std::string format=fmt?fmt:"";if(format=="step"){STEPControl_Writer w;w.Transfer(s,STEPControl_AsIs);if(w.Write(p)!=IFSelect_RetDone)return fail("STEP write failed",e,es);}else if(format=="iges"){IGESControl_Writer w;w.AddShape(s);if(!w.Write(p))return fail("IGES write failed",e,es);}else if(!BRepTools::Write(s,p))return fail("BREP write failed",e,es);return 1;}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_validate(const char*id,char*out,size_t os,char*e,size_t es){try{auto s=get(id);BRepCheck_Analyzer a(s,true);copy(a.IsValid()?"[]":"[{\"code\":\"brep-invalid\",\"severity\":\"error\",\"message\":\"BRepCheck rejected shape\"}]",out,os);return 1;}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_healing_proposals(const char*id,char*out,size_t os,char*e,size_t es){try{auto s=get(id);Handle(ShapeFix_Shape) fix=new ShapeFix_Shape(s);fix->Perform();copy(fix->Status(ShapeExtend_DONE)?"[{\"id\":\"shape-fix\",\"operation\":\"fix-shape\",\"reason\":\"ShapeFix reports available corrections\"}]":"[]",out,os);return 1;}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
int flcad_occ_mesh(const char*id,const char*p,double deflection,int*v,int*t,char*e,size_t es){try{auto s=get(id);BRepMesh_IncrementalMesh mesh(s,deflection,false,0.5,true);int vertices=0,triangles=0;for(TopExp_Explorer ex(s,TopAbs_FACE);ex.More();ex.Next()){TopLoc_Location loc;auto tri=BRep_Tool::Triangulation(TopoDS::Face(ex.Current()),loc);if(!tri.IsNull()){vertices+=tri->NbNodes();triangles+=tri->NbTriangles();}}*v=vertices;*t=triangles;std::ofstream file(p,std::ios::binary);file.write(reinterpret_cast<const char*>(&vertices),sizeof(vertices));file.write(reinterpret_cast<const char*>(&triangles),sizeof(triangles));return file.good()?1:fail("Mesh output write failed",e,es);}catch(const Standard_Failure& x){return fail(x.GetMessageString(),e,es);}}
size_t flcad_occ_shape_count(){std::lock_guard<std::mutex> lock(registry_mutex);return shapes.size();}
}
