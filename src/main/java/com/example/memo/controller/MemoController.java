package com.example.memo.controller;

import com.example.memo.common.Result;
import com.example.memo.entity.Memo;
import com.example.memo.service.MemoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/memo")
@Validated
@CrossOrigin(origins = "*")
public class MemoController {

    @Autowired
    private MemoService memoService;

    @PostMapping("/add")
    public Result<Memo> addMemo(@Valid @RequestBody Memo memo) {
        Memo savedMemo = memoService.addMemo(memo);
        return Result.success("备忘录添加成功", savedMemo);
    }

    @GetMapping("/list")
    public Result<List<Memo>> getAllMemos() {
        List<Memo> memos = memoService.getAllMemos();
        return Result.success("查询成功", memos);
    }

    @GetMapping("/get/{id}")
    public Result<Memo> getMemoById(@PathVariable Long id) {
        Memo memo = memoService.getMemoById(id);
        if (memo == null) {
            return Result.error("备忘录不存在");
        }
        return Result.success("查询成功", memo);
    }

    @DeleteMapping("/delete/{id}")
    public Result<Void> deleteMemo(@PathVariable Long id) {
        boolean deleted = memoService.deleteMemo(id);
        if (!deleted) {
            return Result.error("备忘录不存在或删除失败");
        }
        return Result.successMessage("备忘录删除成功");
    }

    @PutMapping("/update/{id}")
    public Result<Memo> updateMemo(@PathVariable Long id, @Valid @RequestBody Memo memo) {
        Memo updatedMemo = memoService.updateMemo(id, memo);
        if (updatedMemo == null) {
            return Result.error("备忘录不存在");
        }
        return Result.success("备忘录更新成功", updatedMemo);
    }
}
