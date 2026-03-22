package com.example.memo.service;

import com.example.memo.entity.Memo;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class MemoService {

    private final Map<Long, Memo> memoStore = new ConcurrentHashMap<>();
    private final AtomicLong idGenerator = new AtomicLong(1);

    public Memo addMemo(Memo memo) {
        Long id = idGenerator.getAndIncrement();
        memo.setId(id);
        LocalDateTime now = LocalDateTime.now();
        memo.setCreateTime(now);
        memo.setUpdateTime(now);
        memoStore.put(id, memo);
        return memo;
    }

    public List<Memo> getAllMemos() {
        return new ArrayList<>(memoStore.values());
    }

    public Memo getMemoById(Long id) {
        return memoStore.get(id);
    }

    public boolean deleteMemo(Long id) {
        return memoStore.remove(id) != null;
    }

    public Memo updateMemo(Long id, Memo memo) {
        Memo existingMemo = memoStore.get(id);
        if (existingMemo == null) {
            return null;
        }
        existingMemo.setTitle(memo.getTitle());
        existingMemo.setContent(memo.getContent());
        existingMemo.setUpdateTime(LocalDateTime.now());
        return existingMemo;
    }

    public void clearAllMemos() {
        memoStore.clear();
        idGenerator.set(1);
    }
}
