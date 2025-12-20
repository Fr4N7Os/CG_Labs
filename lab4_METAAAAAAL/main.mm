#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <simd/simd.h>
#include <chrono>
#include <unordered_map>

// --- СТРУКТУРЫ ---
struct Vertex {
    simd_float3 position;
    simd_float3 normal;
    simd_float3 color; // Новый параметр
};

struct Uniforms {
    simd_float4x4 modelMatrix;
    simd_float4x4 viewProjectionMatrix;
    simd_float3 cameraPos;
    float _pad1;
    simd_float3 lightPos;
    float _pad2;
    simd_float3 lightColor;
    float _pad3;
};

// --- INPUT DEVICE ---
class InputDevice {
public:
    static InputDevice& getInstance() { static InputDevice instance; return instance; }
    void setKeyState(unsigned short code, bool down) { m_keys[code] = down; }
    bool isKeyDown(unsigned short code) const {
        auto it = m_keys.find(code);
        return (it != m_keys.end()) ? it->second : false;
    }
private:
    std::unordered_map<unsigned short, bool> m_keys;
    InputDevice() {}
};

// --- МАТЕМАТИКА ---
class MathUtils {
public:
    static simd_float4x4 makePerspective(float fovY, float aspect, float n, float f) {
        float ys = 1.0f / tanf(fovY * 0.5f);
        float xs = ys / aspect;
        float zs = f / (n - f);
        return (simd_float4x4){{
            { xs, 0, 0, 0 }, { 0, ys, 0, 0 }, { 0, 0, zs, -1 }, { 0, 0, zs * n, 0 }
        }};
    }
    static simd_float4x4 makeLookAt(simd_float3 eye, simd_float3 target, simd_float3 up) {
        simd_float3 z = simd_normalize(eye - target);
        simd_float3 x = simd_normalize(simd_cross(up, z));
        simd_float3 y = simd_cross(z, x);
        return (simd_float4x4){{
            { x.x, y.x, z.x, 0 }, { x.y, y.y, z.y, 0 }, { x.z, y.z, z.z, 0 },
            { -simd_dot(x, eye), -simd_dot(y, eye), -simd_dot(z, eye), 1 }
        }};
    }
};

// --- RENDERER ---
class Renderer {
public:
    Renderer(MTKView* view) : m_view(view) {
        id<MTLLibrary> lib = [view.device newDefaultLibrary];
        MTLRenderPipelineDescriptor* pd = [MTLRenderPipelineDescriptor new];
        pd.vertexFunction = [lib newFunctionWithName:@"vertex_main"];
        pd.fragmentFunction = [lib newFunctionWithName:@"fragment_main"];
        pd.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        pd.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
        m_pso = [view.device newRenderPipelineStateWithDescriptor:pd error:nil];
        m_queue = [view.device newCommandQueue];
        
        Vertex v[] = {
            // Позиция            Нормаль         Цвет
            // Front (Red)
            {{-0.5,-0.5, 0.5}, {0,0,1}, {1,0,0}}, {{ 0.5,-0.5, 0.5}, {0,0,1}, {1,0,0}}, {{ 0.5, 0.5, 0.5}, {0,0,1}, {1,0,0}},
            {{-0.5,-0.5, 0.5}, {0,0,1}, {1,0,0}}, {{ 0.5, 0.5, 0.5}, {0,0,1}, {1,0,0}}, {{-0.5, 0.5, 0.5}, {0,0,1}, {1,0,0}},
            // Back (Green)
            {{ 0.5,-0.5,-0.5}, {0,0,-1}, {0,1,0}}, {{-0.5,-0.5,-0.5}, {0,0,-1}, {0,1,0}}, {{-0.5, 0.5,-0.5}, {0,0,-1}, {0,1,0}},
            {{ 0.5,-0.5,-0.5}, {0,0,-1}, {0,1,0}}, {{-0.5, 0.5,-0.5}, {0,0,-1}, {0,1,0}}, {{ 0.5, 0.5,-0.5}, {0,0,-1}, {0,1,0}},
            // Top (Blue)
            {{-0.5, 0.5, 0.5}, {0,1,0}, {0,0,1}}, {{ 0.5, 0.5, 0.5}, {0,1,0}, {0,0,1}}, {{ 0.5, 0.5,-0.5}, {0,1,0}, {0,0,1}},
            {{-0.5, 0.5, 0.5}, {0,1,0}, {0,0,1}}, {{ 0.5, 0.5,-0.5}, {0,1,0}, {0,0,1}}, {{-0.5, 0.5,-0.5}, {0,1,0}, {0,0,1}},
            // Bottom (Yellow)
            {{-0.5,-0.5,-0.5}, {0,-1,0}, {1,1,0}}, {{ 0.5,-0.5,-0.5}, {0,-1,0}, {1,1,0}}, {{ 0.5,-0.5, 0.5}, {0,-1,0}, {1,1,0}},
            {{-0.5,-0.5,-0.5}, {0,-1,0}, {1,1,0}}, {{ 0.5,-0.5, 0.5}, {0,-1,0}, {1,1,0}}, {{-0.5,-0.5, 0.5}, {0,-1,0}, {1,1,0}},
            // Right (Magenta)
            {{ 0.5,-0.5, 0.5}, {1,0,0}, {1,0,1}}, {{ 0.5,-0.5,-0.5}, {1,0,0}, {1,0,1}}, {{ 0.5, 0.5,-0.5}, {1,0,0}, {1,0,1}},
            {{ 0.5,-0.5, 0.5}, {1,0,0}, {1,0,1}}, {{ 0.5, 0.5,-0.5}, {1,0,0}, {1,0,1}}, {{ 0.5, 0.5, 0.5}, {1,0,0}, {1,0,1}},
            // Left (Cyan)
            {{-0.5,-0.5,-0.5}, {-1,0,0}, {0,1,1}}, {{-0.5,-0.5, 0.5}, {-1,0,0}, {0,1,1}}, {{-0.5, 0.5, 0.5}, {-1,0,0}, {0,1,1}},
            {{-0.5,-0.5,-0.5}, {-1,0,0}, {0,1,1}}, {{-0.5, 0.5, 0.5}, {-1,0,0}, {0,1,1}}, {{-0.5, 0.5,-0.5}, {-1,0,0}, {0,1,1}},
        };
        m_vbuf = [view.device newBufferWithBytes:v length:sizeof(v) options:MTLResourceStorageModeShared];
    }

    void Update() {
        static float px = 0, py = 0;
        float s = 0.05f;
        if (InputDevice::getInstance().isKeyDown(13)) py += s; // W
        if (InputDevice::getInstance().isKeyDown(1))  py -= s; // S
        if (InputDevice::getInstance().isKeyDown(0))  px -= s; // A
        if (InputDevice::getInstance().isKeyDown(2))  px += s; // D

        static auto start = std::chrono::high_resolution_clock::now();
        float t = std::chrono::duration<float>(std::chrono::high_resolution_clock::now()-start).count();
        float aspect = (float)m_view.drawableSize.width / m_view.drawableSize.height;

        simd_float4x4 model = matrix_identity_float4x4;
        model.columns[3] = (simd_float4){px, py, 0, 1}; // Позиция
        
        // Вращение вокруг Y
        float angle = t;
        simd_float4x4 rot = (simd_float4x4){{
            {cos(angle), 0, -sin(angle), 0}, {0, 1, 0, 0}, {sin(angle), 0, cos(angle), 0}, {0, 0, 0, 1}
        }};

        m_uni.modelMatrix = simd_mul(model, rot);
        m_uni.viewProjectionMatrix = simd_mul(MathUtils::makePerspective(1.1f, aspect, 0.1f, 100.f),
                                             MathUtils::makeLookAt({0,2,5}, {0,0,0}, {0,1,0}));
        m_uni.cameraPos = {0,2,5}; m_uni.lightPos = {2,2,2}; m_uni.lightColor = {1,1,1};
    }

    void Render() {
        id<MTLCommandBuffer> cb = [m_queue commandBuffer];
        MTLRenderPassDescriptor* rpd = m_view.currentRenderPassDescriptor;
        if(rpd) {
            rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.2, 1.0);
            id<MTLRenderCommandEncoder> enc = [cb renderCommandEncoderWithDescriptor:rpd];
            [enc setRenderPipelineState:m_pso];
            [enc setVertexBuffer:m_vbuf offset:0 atIndex:0];
            [enc setVertexBytes:&m_uni length:sizeof(m_uni) atIndex:1];
            [enc setFragmentBytes:&m_uni length:sizeof(m_uni) atIndex:1];
            [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36];
            [enc endEncoding];
            [cb presentDrawable:m_view.currentDrawable];
        }
        [cb commit];
    }

private:
    MTKView* m_view;
    id<MTLCommandQueue> m_queue;
    id<MTLRenderPipelineState> m_pso;
    id<MTLBuffer> m_vbuf;
    Uniforms m_uni;
};

// --- CUSTOM VIEW TO CAPTURE KEYS ---
// Нам нужно переопределить MTKView, чтобы он принимал фокус клавиатуры
@interface MyMTKView : MTKView
@end
@implementation MyMTKView
- (BOOL)acceptsFirstResponder { return YES; }
- (void)keyDown:(NSEvent *)event { InputDevice::getInstance().setKeyState(event.keyCode, true); }
- (void)keyUp:(NSEvent *)event { InputDevice::getInstance().setKeyState(event.keyCode, false); }
@end

// --- APP DELEGATE ---
@interface GameDelegate : NSObject <NSApplicationDelegate, MTKViewDelegate>
@property (strong) NSWindow* window;
@property (strong) MyMTKView* mtkView;
@property Renderer* renderer;
@end

@implementation GameDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,800,600)
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                backing:NSBackingStoreBuffered defer:NO];
    [self.window setTitle:@"Metal WASD Control"];
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self.mtkView = [[MyMTKView alloc] initWithFrame:self.window.contentView.frame device:device];
    self.mtkView.delegate = self;
    self.mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    
    [self.window setContentView:self.mtkView];
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:self.mtkView]; // ОЧЕНЬ ВАЖНО для ввода
    
    self.renderer = new Renderer(self.mtkView);
}
- (void)drawInMTKView:(MTKView *)view { self.renderer->Update(); self.renderer->Render(); }
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}
@end

int main() {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        GameDelegate *delegate = [GameDelegate new];
        app.delegate = delegate;
        [app run];
    }
}
