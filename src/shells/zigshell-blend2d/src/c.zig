// c.zig — Single shared C import for all Zig modules (Blend2D version)
pub const c = @cImport({
    @cInclude("dock_c.h");
});
